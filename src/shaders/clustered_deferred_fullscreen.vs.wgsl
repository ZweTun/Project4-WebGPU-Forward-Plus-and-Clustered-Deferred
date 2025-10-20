// TODO-3: implement the Clustered Deferred fullscreen vertex shader

// This shader should be very simple as it does not need all of the information passed by the the naive vertex shader.


struct VertexOutput {
    @builtin(position) pos: vec4f,
    @location(0) uv: vec2f

}

@vertex
fn main(@builtin(vertex_index) vertexIdx: u32) -> VertexOutput {
    var out: VertexOutput;
    

    //  vertices for a triangle that covers the screen
    var pos = array<vec2f, 3>(
        vec2f(-1.0, -1.0),  // bottom left
        vec2f( 3.0, -1.0),  // bottom right 
        vec2f(-1.0,  3.0)   // top left
    );

    var uvs = array<vec2f, 3>(
        vec2f(0.0, 0.0),  // bottom left
        vec2f(2.0, 0.0),  // bottom right
        vec2f(0.0, 2.0)   // top left
    );


    out.pos = vec4f(pos[vertexIdx], 0.0, 1.0);
    out.uv = uvs[vertexIdx];
    
    return out;
}
