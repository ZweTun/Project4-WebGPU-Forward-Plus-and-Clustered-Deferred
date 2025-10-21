// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.
@group(0) @binding(0) var positionTexture: texture_2d<f32>;
@group(0) @binding(1) var normalTexture: texture_2d<f32>;
@group(0) @binding(2) var albedoTexture: texture_2d<f32>;

@group(1) @binding(0) var<uniform> cameraData: CameraUniforms;
@group(1) @binding(1) var<storage> lightSet: LightSet;
@group(1) @binding(2) var<storage> clusterBoundsSet: ClusterBoundsSet;

struct FragmentInput {
    @builtin(position) fragPos: vec4f,
    @location(0) uv: vec2f
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

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f {

    let albedo = textureLoad(albedoTexture, vec2i(in.fragPos.xy), 0);
    let texCoord = vec2i(in.uv * cameraData.screenDim);
    let texCoordFlipped = vec2i(texCoord.x, i32(cameraData.screenDim[1]) - 1 - texCoord.y);
    let worldPos = textureLoad(positionTexture, texCoordFlipped, 0).xyz;         // flipped sampling
    let normal = normalize(textureLoad(normalTexture, texCoordFlipped, 0).xyz);

    // Get cluster index
    let clusterIdx = getClusterIndexFromFragment(in.fragPos, worldPos);
    
    
    let cluster = &clusterBoundsSet.clusterBounds[clusterIdx];

    var totalLightContrib = vec3<f32>(0.0, 0.0, 0.0);
    
    for (var i = 0u; i < (*cluster).numLights; i++) {
        let lightIdx = (*cluster).lightIndices[i];
        let light = lightSet.lights[lightIdx];
        totalLightContrib += calculateLightContrib(light, worldPos, normal);
    }
    

    let finalColor = albedo.rgb * totalLightContrib;
    return vec4f(finalColor, 1.0);
}
