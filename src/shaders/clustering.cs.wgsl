// TODO-2: implement the light clustering compute shader


// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.


// ------------------------------------
// Assigning lights to clusters:
// ------------------------------------
// For each cluster:
//     - Initialize a counter for the number of lights in this cluster.


//     For each light:
//         - Check if the light intersects with the cluster’s bounding box (AABB).
//         - If it does, add the light to the cluster's light list.
//         - Stop adding lights if the maximum number of lights is reached.


//     - Store the number of lights assigned to this cluster.
   


@group(0) @binding(0) var<storage, read_write> clusterBoundSet: ClusterBoundsSet;

@group(0) @binding(1) var<storage, read_write> lightSet: LightSet;
@group(0) @binding(2) var<uniform> cameraData: CameraUniforms;  


//Changes a points coordinate system from screen space to view space
fn screen2View(screen: vec4<f32>) -> vec3<f32> {
   

    // View space transform
    var view = (cameraData.inverseProjMat * screen).xyz / (cameraData.inverseProjMat * screen).w;

    return view;
}





fn lineIntersectionToZPlane(A : vec3<f32>, B : vec3<f32>, zDistance : f32) -> vec3<f32> {
    // Direction from A to B
    var ab = B - A;

    // Parameter t along the line where z = zDistance
    var t = (zDistance - A.z) / ab.z;

    // Compute intersection point
    var result = A + t * ab;
    return result;
}



fn computeAndStoreAABB(globalIdx: vec3u) {
    // Eye at origin in view space
    let eyePos = vec3<f32>(0.0, 0.0, 0.0);

    
    let clusterX = globalIdx.x;
    let clusterY = globalIdx.y;
    let clusterZ = globalIdx.z;

    // Camera/workgroup info
    let tilesX = u32(cameraData.workGroup.x);
    let tilesY = u32(cameraData.workGroup.y);
    let tilesZ = u32(cameraData.workGroup.z);


    // Flatten 3D index

    let tileIndex = globalIdx.x + globalIdx.y * tilesX + globalIdx.z * tilesX * tilesY;


    // Screen-space coordinates (in pixels)
    let minScreenX = f32(clusterX) / f32(tilesX) * cameraData.screenDim[0];
    let maxScreenX = f32(clusterX + 1u) / f32(tilesX) * cameraData.screenDim[0];
    let minScreenY = f32(clusterY) / f32(tilesY) * cameraData.screenDim[1];
    let maxScreenY = f32(clusterY + 1u) / f32(tilesY) * cameraData.screenDim[1];


    // Convert screen-space corners to clip space
    let clipMin = vec4f( minScreenX / cameraData.screenDim[0] * 2.0 - 1.0,
     (1.0 - minScreenY / cameraData.screenDim[1]) * 2.0 - 1.0, 1.0, 1.0 );
    let clipMax = vec4f(maxScreenX / cameraData.screenDim[0] * 2.0 - 1.0,
     (1.0 - maxScreenY / cameraData.screenDim[1]) * 2.0 - 1.0, 1.0, 1.0
    );


    // Convert to view space
    let minView = screen2View(clipMin);
    let maxView = screen2View(clipMax);

    // Compute near/far distances for this cluster slice
    let tileNear = cameraData.nearPlane * pow(cameraData.farPlane / cameraData.nearPlane, f32(globalIdx.z) / f32(tilesZ));
    let tileFar  = cameraData.nearPlane * pow(cameraData.farPlane / cameraData.nearPlane, f32(globalIdx.z + 1u) / f32(tilesZ));


    let nearViewZ = -tileNear;
    let farViewZ  = -tileFar;

    let minNear = lineIntersectionToZPlane(eyePos, minView, nearViewZ);
    let minFar  = lineIntersectionToZPlane(eyePos, minView, farViewZ);
    let maxNear = lineIntersectionToZPlane(eyePos, maxView, nearViewZ);
    let maxFar  = lineIntersectionToZPlane(eyePos, maxView, farViewZ);


    let minAABB = min(min(minNear, minFar), min(maxNear, maxFar));
    let maxAABB = max(max(minNear, minFar), max(maxNear, maxFar));



    // Store in buffer
    clusterBoundSet.clusterBounds[tileIndex].minPoint = vec4<f32>(minAABB, 0.0);
    clusterBoundSet.clusterBounds[tileIndex].maxPoint = vec4<f32>(maxAABB, 0.0);
  

}






fn checkLightInCluster(light : Light, cluster : ClusterAABB) -> bool {
    // Transform light world-space position into view space using camera viewMat
    let pos4 = cameraData.viewMat * vec4<f32>(light.pos, 1.0);
    let lightPos = pos4.xyz / pos4.w;


    // Cluster AABB in view space
    var mn = cluster.minPoint.xyz;
    var mx = cluster.maxPoint.xyz;


    // Clamp point to AABB
    let closest = vec3<f32>(
        clamp(lightPos.x, mn.x, mx.x),
        clamp(lightPos.y, mn.y, mx.y),
        clamp(lightPos.z, mn.z, mx.z)
    );

    // squared distance
    let dx = closest - lightPos;
    let dist2 = dot(dx, dx);
    let r = ${lightRadius};
    return f32(dist2) <= f32(r * r);
}


fn assignLightsForCluster(clusterIdx: u32) {
    var counter = 0u;
    let clusterPtr = &clusterBoundSet.clusterBounds[clusterIdx]; 
    (*clusterPtr).numLights = 0u;

    for (var lightIdx = 0u; lightIdx < lightSet.numLights; lightIdx++) {
        let light = lightSet.lights[lightIdx];
        if (counter > ${maxNumLights}) {
            break;
        }

        if (checkLightInCluster(light, (*clusterPtr))) {
            (*clusterPtr).lightIndices[counter] = lightIdx;
            counter = counter + 1u;
        } 
    }

    (*clusterPtr).numLights = counter;
}




// CHECKITOUT: this is an example of a compute shader entry point function
@compute
@workgroup_size(${clusterWorkgroupSizeX}, ${clusterWorkgroupSizeY}, ${clusterWorkgroupSizeZ})
fn main(@builtin(global_invocation_id) globalIdx: vec3u) {
   
    let tilesX = u32(cameraData.workGroup.x);
    let tilesY = u32(cameraData.workGroup.y);
    let tilesZ = u32(cameraData.workGroup.z);


    // clamp globalIdx to valid cluster range
    if (globalIdx.x >= u32(tilesX) || globalIdx.y >= u32(tilesY) || globalIdx.z >= u32(tilesZ)) {
        return;
    }


    let clusterIdx = globalIdx.x +
                     globalIdx.y * tilesX +
                     globalIdx.z * tilesX * tilesY;




    // Ensure cluster index is within the actual tile count (use dynamic sizes from cameraData)
    if (clusterIdx >= tilesX * tilesY * tilesZ) {
        return;
    }




    // Compute AABB for this cluster
    computeAndStoreAABB(globalIdx);
   
    // Assign lights to this cluster
    assignLightsForCluster(u32(clusterIdx));




}












