//Shader based on Wunkolo's work:
//https://wunkolo.github.io/post/2022/07/gl_ext_fragment_shader_barycentric-wireframe/
shader_type spatial;

const vec3 vectors[3] = {
	vec3(1.0, 0.0 ,0.0),
	vec3(0.0, 1.0 ,0.0),
	vec3(0.0, 0.0 ,1.0)
};

varying vec3 barycentrics;

void vertex()
{
	barycentrics = vectors[VERTEX_ID % 3];
}

void fragment() {
	
	vec3 dBaryCoordX = dFdx(barycentrics);
	vec3 dBaryCoordY = dFdy(barycentrics);
	vec3 dBaryCoord  = sqrt(dBaryCoordX*dBaryCoordX + dBaryCoordY*dBaryCoordY);

	vec3 Remap = smoothstep(
		vec3(0.0),
		dBaryCoord,
		barycentrics
	);

	float ClosestEdge = min(min(Remap.x, Remap.y), Remap.z);

	ALBEDO = vec3(ClosestEdge);
}