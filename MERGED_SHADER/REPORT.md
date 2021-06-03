# REPORT

## Screen Space Reflection

### Algorithm in general

Screen Space Reflection (SSR) is an algorithm that simulates the reflection of objects in the screen.
We have applied this algorithm for reflecting the screen to the water surface. SSR works by reflecting the screen image onto itself using only itself.

To determine the reflection for each fragment we used the ray marching technique. The algorithm iteratively extends the length of the reflected vector from the fragment in order to sample some space information.
During the calculation of hits, whether or not the reflected ray intersects the screen, we do jump from screen to view space and vicaversa.

We execute the ray marching algorithm during the final pass by extracting the depth information for each fragment from the depth buffer.

Let us call the ray in view space from the camera to the fragment under test (the water fragment) the forward ray. This ray intersects the water surface at the current fragment and its length (distance) is given by the depth buffer (in screen space). The forward ray gets reflected at the current fragment and the reflected ray direction is determined by the normal vector of the current fragment. By the fragment position (interpolated vertex positions) and the normal (interpolated vertex normals) information the direction of the reflected ray is known.

Here comes the iterative process of the algorithm. We need to increment the length of the reflected vector step by step and sample the space whether the reflected ray hits any point in our screen. The iteration can be terminated by defining a maximum length for the reflected ray (indirectly determining the number of iterations, in which the length is incremented iteratively).
An other parameter to define is the delta increment of the vector. It decides the resolution of the process, how many fragments we skip to rerun the process.

We have two passes in our ray marching algorithm. A rough pass that scans the point along the ray where the ray enters or goes behind some geometry.
Then comes the refinement pass which further divides the space and scans for more refined hits within a thickness. 


### Our implementation

You find line by line documentation in the water shader final pass.

We get the color information of the fragment from the color texture stored by previous shaders. We check the entity, in case of water we do launch the ray marching algorithm with parameters; forward ray, normal and reflected ray in view space. All three coordinates are known for the sampled point.
These coordinates are then transformed back to screen space. We check in screen space the corresponding real depth coordinate of the sampled fragment. The real coordinates are then transformed back to view space. In view space we can check the difference between the sampled depth coordinate (calculated by the addition of the forward ray and reflected ray) and the real coordinates. If the difference is small enough we can start a refinement pass and modify the incremented vector accordingly. If there was no hit, difference is larger then expected, we continue with the rough pass. We adjust the visibility at the borders.