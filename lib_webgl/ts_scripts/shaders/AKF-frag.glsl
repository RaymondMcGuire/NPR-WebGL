// by Jan Eric Kyprianidis <www.kyprianidis.com>
precision mediump float;

uniform sampler2D src;
uniform sampler2D k0;
uniform sampler2D tfm;
uniform float radius;
uniform float q;
uniform float alpha;

uniform bool anisotropic;
uniform float cvsHeight;
uniform float cvsWidth;

const float PI = 3.14159265358979323846;
const int N = 8;

void main (void) {
    vec2 src_size = vec2(cvsWidth, cvsHeight);
    vec2 uv = gl_FragCoord.xy / src_size;
	vec2 src_uv = vec2(gl_FragCoord.x / src_size.x, (src_size.y - gl_FragCoord.y) / src_size.y);

    if(anisotropic){
        vec4 m[8];
        vec3 s[8];
        for (int k = 0; k < N; ++k) {
            m[k] = vec4(0.0);
            s[k] = vec3(0.0);
        }

        float piN = 2.0 * PI / float(N);
        mat2 X = mat2(cos(piN), sin(piN), -sin(piN), cos(piN));

        vec4 t = texture2D(tfm, uv);
        float a = radius * clamp((alpha + t.w) / alpha, 0.1, 2.0); 
        float b = radius * clamp(alpha / (alpha + t.w), 0.1, 2.0);

        float cos_phi = cos(t.z);
        float sin_phi = sin(t.z);

        mat2 R = mat2(cos_phi, -sin_phi, sin_phi, cos_phi);
        mat2 S = mat2(0.5/a, 0.0, 0.0, 0.5/b);
        mat2 SR = S * R;

        // int max_x = int(sqrt(a*a * cos_phi*cos_phi +
        //                     b*b * sin_phi*sin_phi));
        // int max_y = int(sqrt(a*a * sin_phi*sin_phi +
        //                     b*b * cos_phi*cos_phi));

        // const int MAX_ITERATIONS = 100;
        // int numBreak = (2*max_x+1) * (2*max_y+1);

        // for (int i = 0; i <= MAX_ITERATIONS; i += 1) {
        //     if(i>=numBreak){break;}

        //     int i_idx = (i - (int(i / (max_x*2+1)))*(max_x*2+1)) - max_x;
        //     int j_idx = (int(i / (max_x*2+1))) - max_y;
        //     vec2 v = SR * vec2(i_idx,j_idx);

        //     float lim = 0.25*255.0;
        //     if (dot(v,v) <= lim) {
        //     vec4 c_fix = texture2D(src, src_uv + vec2(i_idx,j_idx) / src_size);
        //     vec3 c = c_fix.rgb;
        //     for (int k = 0; k < N; ++k) {
        //         float w = texture2D(k0, vec2(0.5, 0.5) + v).x;

        //         m[k] += vec4(c * w, w);
        //         s[k] += c * c * w;

        //         v *= X;
        //         }
        //     }
        // }

        const int max_x = 8;
        const int max_y = 8;

        for (int j = -max_y; j <= max_y; ++j) {
            for (int i = -max_x; i <= max_x; ++i) {
                vec2 v = SR * vec2(i,j);
                if (dot(v,v) <= 0.25) {
                vec4 c_fix = texture2D(src, src_uv + vec2(i,j) / src_size);
                vec3 c = c_fix.rgb;
                for (int k = 0; k < N; ++k) {
                    float w = texture2D(k0, vec2(0.5, 0.5) + v).x;

                    m[k] += vec4(c * w, w);
                    s[k] += c * c * w;

                    v *= X;
                    }
                }
            }
        }

        vec4 o = vec4(0.0);
        for (int k = 0; k < N; ++k) {
            m[k].rgb /= m[k].w;
            s[k] = abs(s[k] / m[k].w - m[k].rgb * m[k].rgb);

            float sigma2 = s[k].r + s[k].g + s[k].b;
            float w = 1.0 / (1.0 + pow(255.0 * sigma2, 0.5 * q));

            o += vec4(m[k].rgb * w, w);
        }

        gl_FragColor = vec4(o.rgb / o.w, 1.0);
    }else{
        gl_FragColor = texture2D(src, src_uv);
    }

}