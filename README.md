# University of Pennsylvania, CIS 5650: GPU Programming and Architecture
## Project 3 - WebGL Forward+ and Clustered Deferred Shading

* Zwe Tun
  * LinkedIn: https://www.linkedin.com/in/zwe-tun-6b7191256/
* Tested on: Intel(R) i7-14700HX, 2100 Mhz, RTX 5060 Laptop
![WebGPU](img/cover.gif)

## Overview  
### Comparison  

| Objects | Naive Shading | Forward+ Shading | Clustered Deferred Shading |
|:--------:|:--------------:|:----------------:|:---------------------------:|
| **100**  | ![Naive 100](img/naive100.gif) | ![Forward 100](img/forward100.gif) | ![Deferred 100](img/deferred100.gif) |
| **1000** | ![Naive 1000](img/naive1000.gif) | ![Forward 1000](img/forward1000.gif) | ![Deferred 1000](img/deferred1000.gif) |
| **2500** | ![Naive 2500](img/naive2500.gif) | ![Forward 2500](img/forward2500.gif) | ![Deferred 2500](img/deferred2500.gif) |
| **5000** | ![Naive 5000](img/naive5000.gif) | ![Forward 5000](img/forward5000.gif) | ![Deferred 5000](img/deferred5000.gif) |

### (TODO: Your README)

*DO NOT* leave the README to the last minute! It is a crucial part of the
project, and we will not be able to grade you without a good README.

This assignment has a considerable amount of performance analysis compared
to implementation work. Complete the implementation early to leave time!

### Credits

- [Vite](https://vitejs.dev/)
- [loaders.gl](https://loaders.gl/)
- [dat.GUI](https://github.com/dataarts/dat.gui)
- [stats.js](https://github.com/mrdoob/stats.js)
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix)
