
uniform sampler2D Sampler;

varying highp vec2 texCoordVarying;

void main() {
    
    mediump vec4 color;
    color = texture2D(Sampler, texCoordVarying);
    gl_FragColor.bgra = vec4(color.b, color.g, color.r, 1.0);
}

