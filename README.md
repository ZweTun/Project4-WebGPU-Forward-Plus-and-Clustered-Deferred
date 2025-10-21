# University of Pennsylvania, CIS 5650: GPU Programming and Architecture
## Project 3 - WebGL Forward+ and Clustered Deferred Shading

* Zwe Tun
  * LinkedIn: https://www.linkedin.com/in/zwe-tun-6b7191256/
* Tested on: Intel(R) i7-14700HX, 2100 Mhz, RTX 5060 Laptop
![WebGPU](img/cover.gif)

## Overview  
This project explores three different implementations of **real-time lighting** in WebGPU.  
The rendered scene is the **Sponza Atrium** model, illuminated by a large number of **point lights**, with a **GUI** that allows switching between rendering modes.

- **Naive Shading**  
- **Forward+ Shading**  
- **Clustered Deferred Shading**  

### Implementation Summary  
- **Naive Shading:**  
  Uses a straightforward GPU-based approach where each fragment iterates through all lights in the scene to compute illumination.  
  This brute-force method is easy to implement but becomes prohibitively expensive as the number of lights increases due to its **O(N×L)** complexity (N = fragments, L = lights).

  1. **Vertex Shader:** Transforms geometry into clip space.  
  2. **Fragment Shader:**  
     - For each pixel, iterate over **every light** in the scene.  
     - Compute diffuse and specular contributions using the Phong or Blinn-Phong lighting model.  
     - Accumulate results and output the final color.  
  3. **Final Output:** Display the shaded image.  


- **Forward+ Shading:**  
  Divides the view frustum into 3D clusters and assigns lights to these clusters based on AABB (Axis-Aligned Bounding Box) intersection tests.  
  In the fragment shader, each pixel only considers lights within its cluster. This drastically reduces redundant light calculations by exploiting light attenuation, ignoring lights too far to meaningfully affect shading.

   1. **Cluster Generation:**  
     - Subdivide the frustum into clusters (e.g., 16×8×24).  
     - Compute the min/max depth per cluster.  
  2. **Light Assignment:**  
     - For each light, test which clusters it overlaps using AABB intersection.  
     - Store light indices per cluster in a GPU buffer.  
  3. **Rendering Pass:**  
     - Render geometry normally.  
     - In the fragment shader, determine the fragment’s cluster.  
     - Retrieve that cluster’s light list and compute lighting using only nearby lights.  
  4. **Final Output:** Display the shaded image.  


- **Clustered Deferred Shading:**  
  Extends the Forward+ approach by spliting lighting from geometry so it is now done in 2 passes. This allows for even more effcient lighting with complex scenes and large light counts.
  1. **G-Buffer Pass:** Stores material and geometric information (positions, normals, albedo) for each fragment.
  2. **Light Clustering:**  
     - Perform the same light assignment to 3D clusters as in Forward+.  
  4. **Lighting Pass:**  
     - For each screen pixel, determine its cluster and retrieve relevant lights.  
     - Compute lighting entirely in screen space using G-buffer data (no additional geometry traversal).
  5. **Final Output:** Display the shaded image.
 
 ### Debugging via Fragment Shader Visualization  

To verify correctness during development, I used the fragment shader to visualize G-buffer outputs. By returning different texture samples from the shader, I could confirm that data written (such as world positions, normals, and albedo) aligned correctly.

- **World Position Visualization:**  

- **Normal Visualization:**  

- **Albedo Visualization:**  


### Comparison  

| Number of Lights | Naive Shading | Forward+ Shading | Clustered Deferred Shading |
|:--------:|:--------------:|:----------------:|:---------------------------:|
| **100**  | ![Naive 100](img/naive100.gif) | ![Forward 100](img/forward100.gif) | ![Deferred 100](img/deferred100.gif) |
| **1000** | ![Naive 1000](img/naive1000.gif) | ![Forward 1000](img/forward1000.gif) | ![Deferred 1000](img/deferred1000.gif) |
| **2500** | ![Naive 2500](img/naive2500.gif) | ![Forward 2500](img/forward2500.gif) | ![Deferred 2500](img/deferred2500.gif) |
| **5000** | ![Naive 5000](img/naive5000.gif) | ![Forward 5000](img/forward5000.gif) | ![Deferred 5000](img/deferred5000.gif) |


### Performance Analysis  
![WebGPU](img/renderPerf.png)


As we can see naive performs okay for small light counts at ~100 lights but scales poorly. Beyond 500 lights, the naive approach becomes bottlenecked by the loop that checks for every light in the scene. It's performance drops sharply as a result. Forward+ Shading provides a better performance boost by limiting light evaluations per cluster, resulting in greater frames than naive. Clustered Deferred Shading however sees the greatest improvement beating out both other implementations for all light numbers. 




### Credits

- [Vite](https://vitejs.dev/)
- [loaders.gl](https://loaders.gl/)
- [dat.GUI](https://github.com/dataarts/dat.gui)
- [stats.js](https://github.com/mrdoob/stats.js)
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix)
