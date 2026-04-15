shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;

// Define the exact size of your BlurPanel in pixels to avoid oval corners
uniform vec2 panel_size = vec2(230.0, 100.0);
// Define the radius of the corners in pixels
uniform float corner_radius = 15.0;

void fragment() {
    vec4 blur = textureLod(screen_texture, SCREEN_UV, blur_amount);
    
    // Calculate pixel coordinates relative to the center of the panel
    vec2 half_size = panel_size / 2.0;
    vec2 pixel_pos = (UV - 0.5) * panel_size;
    
    // Calculate the distance field for a rounded box
    vec2 d = abs(pixel_pos) - (half_size - corner_radius);
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - corner_radius;
    
    // Create a smooth mask based on the distance
    float mask = 1.0 - smoothstep(-1.0, 1.0, dist);
    
    // Mix the blur with a slight white tint and apply the mask
    vec4 final_color = mix(blur, vec4(1.0, 1.0, 1.0, 1.0), 0.15);
    COLOR = vec4(final_color.rgb, final_color.a * mask);
}
