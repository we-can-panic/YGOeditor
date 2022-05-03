import strformat
include karax/prelude


func drawPoint* (r=5.0, color="#000000"): VNode =
  let d = 2*r
  buildHtml tdiv:
    verbatim fmt"""
    <svg  class="point" x="0px" y="0px" width="{d}px" height="{d}px"
          viewBox="0 0 {d} {d}" xmlns="http://www.w3.org/2000/svg">
      <circle cx="{r}" cy="{r}" r="{r}" fill="{color}"/>
    </svg>
    """

func drawStar* (x, y: float, color="#000000"): VNode =
  let
    (x1, x2, x3, x4, x5) = (x*0.02, x*0.21, x*0.50, x*0.79, x*0.98)
    (y1, y2, y3) = (y*0.1, y*0.45, y*1.0)
  buildHtml tdiv:
    verbatim fmt"""
    <svg  class="point" x="0px" y="0px" width="{x}px" height="{y}px"
          viewBox="0 0 {x} {y}" xmlns="http://www.w3.org/2000/svg">
      <polygon  fill="{color}"
                points="{x1},{y2} {x5},{y2} {x2},{y3} {x3},{y1} {x4},{y3}"/>
    </svg>
    """
func drawStar* (x=20, y=20, color="#000000"): VNode =
  drawStar(x.toFloat, y.toFloat, color)

func drawNone* (): VNode =
  drawPoint(color="rgba(0,0,0,0)")

## not used
func drawRound* (x, y, w, h: float, color="#000000"): VNode =
  let (cx, cy) = ((x+w)/2, (y+h)/2)
  buildHtml tdiv:
    verbatim fmt"""
    <svg  style="position: absolute; z-index: 5; top: {x}px; left: {y}px;"
          x="0px" y="0px" width="{w}px" height="{h}px"
          viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">
      <circle cx="{cx}" cy="{cy}" r="10" fill="{color}"/>
    </svg>
    """
func drawRound* (x, y, w, h: int, color="#000000"): VNode =
  drawRound(x.toFloat, y.toFloat, w.toFloat, h.toFloat, color)

func drawArrow* (x, y, w, h: float, color="#000000"): VNode =
  let
    (x1, x2, x3, x4, x5) = (w*0.3, w*0.45, w*0.5, w*0.55, w*0.7)
    (y1, y2, y3) = (h*0.0, h-10, h*1.0)
  buildHtml tdiv:
    verbatim fmt"""
    <svg  style="position: absolute; z-index: 5; top: {x}px; left: {y}px;"
          x="0px" y="0px" width="{w}px" height="{h}px"
          viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg">
      <polygon  fill="{color}"
                points="{x2},{y1} {x2},{y2} {x1},{y2} {x3},{y3} {x5},{y2} {x4},{y2} {x4},{y1}"/>
    </svg>
    """
func drawArrow* (x, y, w, h: int, color="#000000"): VNode =
  drawArrow(x.toFloat, y.toFloat, w.toFloat, h.toFloat, color)