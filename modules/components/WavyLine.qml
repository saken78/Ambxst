import QtQuick
import QtQuick.Shapes
import qs.config
import qs.modules.theme

Item {
    id: root

    // =========================================================================
    // API Properties
    // =========================================================================
    property color color: Styling.srItem("overprimary")
    property real lineWidth: 2
    property real frequency: 2
    property real amplitude: 4
    property real speed: 5
    property bool running: true

    // Compatibility properties
    property real amplitudeMultiplier: 1.0 // Legacy support
    property real fullLength: width
    property bool animationsEnabled: true
    
    // Enable clipping on the root item to hide the scrolling part
    clip: true

    // =========================================================================
    // Internal Logic
    // =========================================================================

    property real actualAmplitude: amplitude * amplitudeMultiplier
    
    // Calculate cycle length in pixels: width / frequency
    // If frequency is 0, avoid division by zero
    readonly property real cyclePx: (frequency > 0 && width > 0) ? (width / frequency) : width

    // Animation Phase (Translation)
    // We animate 't' from 0 to 1 over the duration of one cycle
    property real t: 0
    
    NumberAnimation on t {
        running: root.running && root.visible && root.animationsEnabled && root.width > 0
        from: 0
        to: 1
        duration: 1000
        loops: Animation.Infinite
    }

    // Static Path Generation
    property var staticPoints: []

    function updateStaticPath() {
        if (root.width <= 0) return;
        
        let points = [];
        let w = root.width;
        let h = root.height;
        let centerY = h / 2;
        let freq = root.frequency > 0 ? root.frequency : 1;
        let amp = root.actualAmplitude;
        
        // Cycle length in pixels
        let cyclePx = w / freq;
        
        // Step size: 1px for smoothness
        let step = 1; 
        
        // Generate points for Width + 1 Cycle
        let totalWidth = w + cyclePx;

        for (let x = 0; x <= totalWidth + step; x += step) {
            // Angle: Map x to angle where w = freq * 2PI
            let angle = (x / w) * freq * 2 * Math.PI;
            
            let yOffset = Math.sin(angle) * amp;
            points.push(Qt.point(x, centerY + yOffset));
        }
        root.staticPoints = points;
    }

    onWidthChanged: updateStaticPath()
    onHeightChanged: updateStaticPath()
    onFrequencyChanged: updateStaticPath()
    onActualAmplitudeChanged: updateStaticPath()
    Component.onCompleted: updateStaticPath()

    Shape {
        id: shape
        // Don't fill parent directly, let us control size
        width: root.width + root.cyclePx
        height: root.height
        
        // Animate X position of the whole Shape
        x: -root.t * root.cyclePx
        
        // Use preferredRendererType: Shape.CurveRenderer for smooth lines
        preferredRendererType: Shape.CurveRenderer
        
        // Disable internal clip of Shape if needed, but we clip at root
        // clip: false 

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            
            // Start at 0 relative to Shape
            startX: polyline.path.length > 0 ? polyline.path[0].x : 0
            startY: polyline.path.length > 0 ? polyline.path[0].y : root.height / 2

            PathPolyline {
                id: polyline
                path: root.staticPoints
            }
        }
    }
}
