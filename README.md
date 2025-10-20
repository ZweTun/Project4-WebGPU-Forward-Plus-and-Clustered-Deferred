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

- **Forward+ Shading:**  
  Divides the view frustum into 3D clusters and assigns lights to these clusters based on AABB (Axis-Aligned Bounding Box) intersection tests.  
  In the fragment shader, each pixel only considers lights within its cluster. This drastically reduces redundant light calculations by exploiting light attenuation, ignoring lights too far to meaningfully affect shading.

- **Clustered Deferred Shading:**  
  Extends the Forward+ idea by introducing **two passes**:
  1. **G-Buffer Pass:** Stores material and geometric information (positions, normals, albedo) for each fragment.
  2. **Lighting Pass:** Performs lighting computations in screen space using clustered light data.  
  This approach splits lighting from geometry, allowing for even more effcient lighting with complex scenes and large light counts.


### Comparison  

| Number of Lights | Naive Shading | Forward+ Shading | Clustered Deferred Shading |
|:--------:|:--------------:|:----------------:|:---------------------------:|
| **100**  | ![Naive 100](img/naive100.gif) | ![Forward 100](img/forward100.gif) | ![Deferred 100](img/deferred100.gif) |
| **1000** | ![Naive 1000](img/naive1000.gif) | ![Forward 1000](img/forward1000.gif) | ![Deferred 1000](img/deferred1000.gif) |
| **2500** | ![Naive 2500](img/naive2500.gif) | ![Forward 2500](img/forward2500.gif) | ![Deferred 2500](img/deferred2500.gif) |
| **5000** | ![Naive 5000](img/naive5000.gif) | ![Forward 5000](img/forward5000.gif) | ![Deferred 5000](img/deferred5000.gif) |


### Performance Analysis  
![WebGPU](img/renderPerf.png)
As we can see naive performs okay for small light counts but scales poorly. It's performance drops sharply as lights exceed a few hundred. Forward+ Shading provides a better performance boost by limiting light evaluations per cluster, resulting in greater frames than naive. Clustered Deferred Shading however sees the greatest improvement beating out both other implementations for all light numbers. 

### Credits

- [Vite](https://vitejs.dev/)
- [loaders.gl](https://loaders.gl/)
- [dat.GUI](https://github.com/dataarts/dat.gui)
- [stats.js](https://github.com/mrdoob/stats.js)
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix)
