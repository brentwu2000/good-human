// GOOD HUMAN! soft toon (Style Bible v1 §Material): one shared shader for every character.
// A smooth two-band diffuse (soft terminator, not a hard anime cut), lavender-tinted shade,
// no specular, full roughness, optional normal map at reduced strength.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform bool use_albedo_tex = false;
uniform bool use_vertex_color = false;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D normal_tex : hint_normal;
uniform bool use_normal = false;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.5;
uniform float band_softness : hint_range(0.01, 0.5) = 0.18;
uniform float band_offset : hint_range(-0.5, 0.5) = 0.0;
uniform float shade_level : hint_range(0.0, 1.0) = 0.58;
uniform vec4 shade_tint : source_color = vec4(0.86, 0.82, 0.95, 1.0);

void fragment() {
	vec4 c = albedo_color;
	if (use_albedo_tex) {
		c *= texture(albedo_tex, UV);
	}
	if (use_vertex_color) {
		c.rgb *= COLOR.rgb;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float t = smoothstep(band_offset - band_softness, band_offset + band_softness, ndl) * ATTENUATION;
	vec3 band = mix(shade_tint.rgb * shade_level, vec3(1.0), t);
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
}
