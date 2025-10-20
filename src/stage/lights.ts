import { vec3 } from "wgpu-matrix";
import { device } from "../renderer";

import * as shaders from '../shaders/shaders';
import { Camera } from "./camera";

// h in [0, 1]
function hueToRgb(h: number) {
    let f = (n: number, k = (n + h * 6) % 6) => 1 - Math.max(Math.min(k, 4 - k, 1), 0);
    return vec3.lerp(vec3.create(1, 1, 1), vec3.create(f(5), f(3), f(1)), 0.8);
}



export class Lights {
    private camera: Camera;

    numLights = 100;
    static readonly maxNumLights = 5000;
    static readonly numFloatsPerLight = 8; // vec3f is aligned at 16 byte boundaries

    static readonly lightIntensity = 0.1;

    lightsArray = new Float32Array(Lights.maxNumLights * Lights.numFloatsPerLight);
    lightSetStorageBuffer: GPUBuffer;

    timeUniformBuffer: GPUBuffer;

    moveLightsComputeBindGroupLayout: GPUBindGroupLayout;
    moveLightsComputeBindGroup: GPUBindGroup;
    moveLightsComputePipeline: GPUComputePipeline;

    // TODO-2: add layouts, pipelines, textures, etc. needed for light clustering here
   
    clusterBoundsBuffer : GPUBuffer;

    clusterComputeBindGroupLayout : GPUBindGroupLayout; 
    clusterComputeBindGroup : GPUBindGroup; 
    clusterComputePipeline : GPUComputePipeline;
    
    //16x9x24 tile size 
    NUM_CLUSTERS = shaders.constants.numClusterX *
                    shaders.constants.numClusterY *
                    shaders.constants.numClusterZ;

    MAX_LIGHTS_PER_CLUSTER = shaders.constants.maxNumLights;

    BYTES_PER_VEC4 = 16;
    BYTES_PER_U32 = 4;

    // Raw size of one cluster: minPoint + maxPoint + numLights + lightIndices[]
    RAW_CLUSTER_SIZE =
        2 * this.BYTES_PER_VEC4 +                  // minPoint + maxPoint
        this.BYTES_PER_U32 +                       // numLights
        this.BYTES_PER_U32 * this.MAX_LIGHTS_PER_CLUSTER; // lightIndices array

    // Align each cluster entry to 16 bytes 
    PADDED_CLUSTER_SIZE = Math.ceil(this.RAW_CLUSTER_SIZE / 16) * 16;

    // Final buffer size for all clusters
    CLUSTER_SET_BUFFER_SIZE = this.NUM_CLUSTERS * this.PADDED_CLUSTER_SIZE;
        
    constructor(camera: Camera) {
        
        this.camera = camera;

        this.lightSetStorageBuffer = device.createBuffer({
            label: "lights",
            size: 16 + this.lightsArray.byteLength, // 16 for numLights + padding
            usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
        });
        this.populateLightsBuffer();
        this.updateLightSetUniformNumLights();

        this.timeUniformBuffer = device.createBuffer({
            label: "time uniform",
            size: 4,
            usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
        });

        this.moveLightsComputeBindGroupLayout = device.createBindGroupLayout({
            label: "move lights compute bind group layout",
            entries: [
                { // lightSet
                    binding: 0,
                    visibility: GPUShaderStage.COMPUTE,
                    buffer: { type: "storage" }
                },
                { // time
                    binding: 1,
                    visibility: GPUShaderStage.COMPUTE,
                    buffer: { type: "uniform" }
                }
            ]
        });

        this.moveLightsComputeBindGroup = device.createBindGroup({
            label: "move lights compute bind group",
            layout: this.moveLightsComputeBindGroupLayout,
            entries: [
                {
                    binding: 0,
                    resource: { buffer: this.lightSetStorageBuffer }
                },
                {
                    binding: 1,
                    resource: { buffer: this.timeUniformBuffer }
                }
            ]
        });

        this.moveLightsComputePipeline = device.createComputePipeline({
            label: "move lights compute pipeline",
            layout: device.createPipelineLayout({
                label: "move lights compute pipeline layout",
                bindGroupLayouts: [ this.moveLightsComputeBindGroupLayout ]
            }),
            compute: {
                module: device.createShaderModule({
                    label: "move lights compute shader",
                    code: shaders.moveLightsComputeSrc
                }),
                entryPoint: "main"
            }
        });
        
      
      
        // TODO-2: initialize layouts, pipelines, textures, etc. needed for light clustering here
        // Cluster bounds buffer (AABB per cluster)



        // TODO-2: initialize layouts, pipelines, textures, etc. needed for light clustering here

 

        this.clusterBoundsBuffer = device.createBuffer({
            label: "cluster bounds",
            size: this.CLUSTER_SET_BUFFER_SIZE,
            usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST
        });



        // Bind group layout for clustering compute
        this.clusterComputeBindGroupLayout = device.createBindGroupLayout({
            label: "cluster compute bind group layout",
            entries: [
                { binding: 0, visibility: 
                    GPUShaderStage.COMPUTE, 
                    buffer: { type: "storage" } }, // Cluster bounds
   
                { binding: 1, visibility: 
                    GPUShaderStage.COMPUTE, 
                    buffer: { type: "storage" } }, // LightSet
                { binding: 2, visibility: 
                    GPUShaderStage.COMPUTE, 
                    buffer: { type: "uniform" } }  // Camera
            ]
        });

        // Bind group for compute pass
        this.clusterComputeBindGroup = device.createBindGroup({
            label: "cluster compute bind group",
            layout: this.clusterComputeBindGroupLayout,
            entries: [
                { binding: 0, resource: { buffer: this.clusterBoundsBuffer } },
                // { binding: 1, resource: { buffer: this.clusterSetBuffer } },
                { binding: 1, resource: { buffer: this.lightSetStorageBuffer } },
                { binding: 2, resource: { buffer: this.camera.uniformsBuffer } }
            ]
        });


        this.clusterComputePipeline = device.createComputePipeline({
            layout: device.createPipelineLayout({
                bindGroupLayouts: [this.clusterComputeBindGroupLayout]
            }),
            compute: {
                module: device.createShaderModule({ code: shaders.clusteringComputeSrc }),
                entryPoint: "main"
            }
        });


        


        
    }

    private populateLightsBuffer() {
        for (let lightIdx = 0; lightIdx < Lights.maxNumLights; ++lightIdx) {
            // light pos is set by compute shader so no need to set it here
            const lightColor = vec3.scale(hueToRgb(Math.random()), Lights.lightIntensity);
            this.lightsArray.set(lightColor, (lightIdx * Lights.numFloatsPerLight) + 4);
        }

        device.queue.writeBuffer(this.lightSetStorageBuffer, 16, this.lightsArray);
    }

    updateLightSetUniformNumLights() {
        device.queue.writeBuffer(this.lightSetStorageBuffer, 0, new Uint32Array([this.numLights]));
    }

    updateClusterBoundNumClusters() {
        device.queue.writeBuffer(this.clusterBoundsBuffer, 0,  new Uint32Array([this.NUM_CLUSTERS]));
    }

    doLightClustering(encoder: GPUCommandEncoder) {
        // TODO-2: run the light clustering compute pass(es) here
        //implementing clustering here allows for reusing the code in both Forward+ and Clustered Deferred
    
        //Start new compute pass for light clustering
        const computePass = encoder.beginComputePass();
        computePass.setPipeline(this.clusterComputePipeline);

        // Bind  resources for clustering 
        computePass.setBindGroup(0, this.clusterComputeBindGroup);

        // Dispatch 
        const workgroupCountX = Math.ceil(shaders.constants.numClusterX / shaders.constants.clusterWorkgroupSizeX);
        const workgroupCountY = Math.ceil(shaders.constants.numClusterY / shaders.constants.clusterWorkgroupSizeY);
        const workgroupCountZ = Math.ceil(shaders.constants.numClusterZ / shaders.constants.clusterWorkgroupSizeZ);

        computePass.dispatchWorkgroups(workgroupCountX, workgroupCountY, workgroupCountZ);

        computePass.end();


    }



    // CHECKITOUT: this is where the light movement compute shader is dispatched from the host
    onFrame(time: number) {
        device.queue.writeBuffer(this.timeUniformBuffer, 0, new Float32Array([time]));

        // not using same encoder as render pass so this doesn't interfere with measuring actual rendering performance
        const encoder = device.createCommandEncoder();

        const computePass = encoder.beginComputePass();
        computePass.setPipeline(this.moveLightsComputePipeline);

        computePass.setBindGroup(0, this.moveLightsComputeBindGroup);

        const workgroupCount = Math.ceil(this.numLights / shaders.constants.moveLightsWorkgroupSize);
        computePass.dispatchWorkgroups(workgroupCount);

        computePass.end();

        device.queue.submit([encoder.finish()]);
         

    
    }
}
