#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float angle;
    float dotMinSize;
    float dotMaxSize;
    float gradientStart;
    float gradientEnd;
    vec4 dotColor;
    vec4 backgroundColor;
    float canvasWidth;
    float canvasHeight;
    float dotSpread;
} ubuf;

#define PI 3.14159265359

void main() {
    vec2 pixelPos = qt_TexCoord0 * vec2(ubuf.canvasWidth, ubuf.canvasHeight);
    
    float angleRad = radians(ubuf.angle);
    
    // Tamaño de celda basado en spread
    float cellSize = ubuf.dotMaxSize * ubuf.dotSpread;
    
    // Matriz de rotación
    mat2 rotation = mat2(
        cos(angleRad), -sin(angleRad),
        sin(angleRad), cos(angleRad)
    );
    
    vec2 center = vec2(ubuf.canvasWidth * 0.5, ubuf.canvasHeight * 0.5);
    
    // Rotar posición
    vec2 rotatedPos = rotation * (pixelPos - center);
    
    // Grid y celda
    vec2 gridPos = rotatedPos / cellSize;
    vec2 cellIndex = floor(gridPos);
    vec2 cellCenter = (cellIndex + 0.5) * cellSize;
    vec2 posInCell = rotatedPos - cellCenter;
    
    float distToCenter = length(posInCell);
    
    // Calcular posición del gradiente
    // Usar vector perpendicular al ángulo para ir de arriba a abajo por defecto (90°)
    vec2 gradientDir = vec2(sin(angleRad), -cos(angleRad));
    vec2 relativePos = pixelPos - center;
    float projection = dot(relativePos, gradientDir);
    
    // Normalizar e invertir para que vaya de max a min (arriba a abajo)
    float diagonal = sqrt(ubuf.canvasWidth * ubuf.canvasWidth + ubuf.canvasHeight * ubuf.canvasHeight);
    float gradientPos = 1.0 - ((projection / diagonal) * 0.5 + 0.5);
    
    // Interpolar tamaño del dot
    float t = smoothstep(ubuf.gradientStart, ubuf.gradientEnd, gradientPos);
    float dotRadius = mix(ubuf.dotMinSize, ubuf.dotMaxSize, t);
    
    // Bordes sólidos sin antialiasing
    float alpha = step(distToCenter, dotRadius);
    
    // Mezclar colores
    vec4 finalColor = mix(ubuf.backgroundColor, ubuf.dotColor, alpha);
    
    fragColor = vec4(finalColor.rgb, finalColor.a * ubuf.qt_Opacity);
}

