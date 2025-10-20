// TODO-2: implement the Forward+ fragment shader

// See naive.fs.wgsl for basic fragment shader setup; this shader should use light clusters instead of looping over all lights

// ------------------------------------
// Shading process:
// ------------------------------------
// Determine which cluster contains the current fragment.
// Retrieve the number of lights that affect the current fragment from the cluster’s data.
// Initialize a variable to accumulate the total light contribution for the fragment.
// For each light in the cluster:
//     Access the light's properties using its index.
//     Calculate the contribution of the light based on its position, the fragment’s position, and the surface normal.
//     Add the calculated contribution to the total light accumulation.
// Multiply the fragment’s diffuse color by the accumulated light contribution.
// Return the final color, ensuring that the alpha component is set appropriately (typically to 1).


@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;


@group(0) @binding(0) var<uniform> cameraData: CameraUniforms;   
@group(0) @binding(1) var<storage, read> lightSet: LightSet;
@group(0) @binding(2) var<storage, read_write> clusterBoundsSet: ClusterBoundsSet;

struct FragmentInput
{
    @builtin(position) fragPos: vec4f,
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
    
}


fn getClusterIndexFromFragment(fragPixel: vec4f, fragPosWorld: vec3f) -> u32 {

    let clusterX = u32(fragPixel.x / cameraData.screenDim[0] * f32(cameraData.workGroup.x));
    let clusterY = u32(fragPixel.y / cameraData.screenDim[1] * f32(cameraData.workGroup.y));
    
    let viewPos = (cameraData.viewMat * vec4f(fragPosWorld, 1.0)).xyz;
    let viewDepth = -viewPos.z;
    let near = cameraData.nearPlane;
    let far = cameraData.farPlane;
    let clusterZ = u32(log(viewDepth / near) / log(far / near) * f32(cameraData.workGroup.z));

    return (clusterX + clusterY * cameraData.workGroup.x + clusterZ * cameraData.workGroup.x * cameraData.workGroup.y);


}




// Scalar helpers for debug 
fn isNan(x: f32) -> bool {
    // NaN is the only float that is not equal to itself
    return x != x;
}

fn isInf(x: f32) -> bool {
    // Exclude NaN first, then test if abs(x) is infinite by dividing by itself
    // For finite non-zero numbers (including subnormal) x/x == 1.0
    // For infinities x/x yields NaN, so detect via inequality to 1.0
    if (isNan(x)) {
        return false;
    }
    // handle zero separately (0.0/0.0 -> NaN)
    if (x == 0.0) {
        return false;
    }
    return (x / x) != 1.0;
}



fn isNan_vec2(x: vec2<f32>) -> vec2<bool> {
    return vec2<bool>(isNan(x.x), isNan(x.y));
}

fn isNan_vec4(x: vec4<f32>) -> vec4<bool> {
    return vec4<bool>(isNan(x.x), isNan(x.y), isNan(x.z), isNan(x.w));
}


fn isInf_vec4(x: vec4<f32>) -> vec4<bool> {
    return vec4<bool>(isInf(x.x), isInf(x.y), isInf(x.z), isInf(x.w));
}

fn isInf_vec2(x: vec2<f32>) -> vec2<bool> {
    return vec2<bool>(isInf(x.x), isInf(x.y));
}

fn isNan_vec3(x: vec3<f32>) -> vec3<bool> {
    return vec3<bool>(isNan(x.x), isNan(x.y), isNan(x.z));
}

fn isInf_vec3(x: vec3<f32>) -> vec3<bool> {
    return vec3<bool>(isInf(x.x), isInf(x.y), isInf(x.z));
}






@fragment
fn main(in: FragmentInput) -> @location(0) vec4<f32> {


    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }


    let clusterIdx = getClusterIndexFromFragment(in.fragPos, in.pos); 

    let cluster = &clusterBoundsSet.clusterBounds[clusterIdx];
    var totalLightContrib = vec3<f32>(0.0, 0.0, 0.0);

    for (var i = 0u; i < (*cluster).numLights; i++) {
        let lightIdx = (*cluster).lightIndices[i];
        let light = lightSet.lights[lightIdx];
        totalLightContrib += calculateLightContrib(light, in.pos, normalize(in.nor));
    }

    let finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4<f32>(finalColor, 1.0);


} 
  