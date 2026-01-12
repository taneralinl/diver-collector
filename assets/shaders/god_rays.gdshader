shader_type canvas_item;

uniform vec4 ray_color : source_color = vec4(0.4, 0.7, 0.9, 0.15);
uniform float speed = 0.5;
uniform float ray_count = 8.0;

void fragment() {
    vec2 uv = UV;
    float rays = 0.0;
    
    for (float i = 0.0; i < ray_count; i++) {
        float offset = i * (1.0 / ray_count);
        float x = mod(uv.x + sin(TIME * speed + offset * 10.0) * 0.1, 1.0);
        float width = 0.1 + abs(sin(TIME * 0.2 + offset)) * 0.1;
        float dist = abs(x - offset);
        if (dist < width) {
            rays += (1.0 - (dist / width)) * (1.0 - uv.y);
        }
    }
    
    COLOR = ray_color * rays;
}
