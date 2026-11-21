shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;

// 0 = normal, 1 = layar tertutup penuh warna biru muda
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);

uniform vec4 tint_color : source_color = vec4(0.50, 0.82, 1.0, 1.0); // biru muda
uniform vec4 glow_color : source_color = vec4(0.88, 0.97, 1.0, 1.0); // putih kebiruan

uniform float distortion = 0.06;
uniform float ripple_freq = 28.0;
uniform float ripple_speed = 6.0;
uniform float chroma = 0.012;
uniform float noise_amount = 0.08;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 d = (uv - center) * aspect;
	float dist = length(d);
	vec2 dir = d / max(dist, 0.0001);
	vec2 dir_uv = dir / aspect;

	// Jarak dari titik asal (posisi pemain) ke sudut layar terjauh,
	// supaya ring selalu sempat menjangkau seluruh layar
	vec2 c0 = center * aspect;
	float max_dist = max(
		max(length(c0), length(c0 - vec2(aspect.x, 0.0))),
		max(length(c0 - vec2(0.0, 1.0)), length(c0 - aspect))
	);

	// 1) Ripple distorsi + tarikan ke pusat
	float falloff = smoothstep(1.4, 0.0, dist);
	float wave = sin(dist * ripple_freq - TIME * ripple_speed);
	vec2 suv = uv + dir_uv * wave * distortion * intensity * falloff;
	suv = mix(suv, center, intensity * intensity * 0.2 * falloff);

	// 2) Chromatic aberration
	float ca = chroma * intensity;
	vec3 col = vec3(
		texture(screen_tex, suv + dir_uv * ca).r,
		texture(screen_tex, suv).g,
		texture(screen_tex, suv - dir_uv * ca).b
	);

	// 3) Warna bergeser dominan biru muda
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 blue = tint_color.rgb * (lum * 1.3 + 0.12);
	col = mix(col, blue, clamp(intensity * 1.2, 0.0, 1.0) * 0.9);

	// 4) Ring cahaya yang melebar + flash di pusat
	// Ring mulai dari posisi pemain (radius 0) lalu melebar
	float radius = intensity * max_dist;
	float ring = exp(-pow((dist - radius) * 7.0, 2.0));
	float flash = pow(intensity, 3.0) * smoothstep(1.0, 0.0, dist);
	col += glow_color.rgb * (ring * 0.7 * smoothstep(0.0, 0.1, intensity) + flash * 0.8 * intensity);

	// 5) Vignette biru di tepi layar
	col = mix(col, tint_color.rgb, smoothstep(0.4, 1.2, dist) * intensity * 0.35);

	// 6) Menutup layar saat puncak (aman untuk swap realitas)
	float cover = smoothstep(0.88, 1.0, intensity);
	col = mix(col, glow_color.rgb, cover * 0.85);

	// 7) Grain halus
	col += (hash(SCREEN_UV * 1000.0 + fract(TIME)) - 0.5) * noise_amount * intensity;

	COLOR = vec4(col, 1.0);
}
