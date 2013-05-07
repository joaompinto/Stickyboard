import 'dart:html';
import 'dart:svg';
import 'package:js/js.dart' as js;

class PlacedImage {
  CanvasElement img;
  num x, y;
  PlacedImage(this.img, this.x, this.y);
}

class StickyboardApp {
  var active_toolbutton = null;
  var prev_active_toolbutton = null; // previous toolbutton
  CanvasElement canvas;
  num mouseX = null, mouseY = null;
  var canvasBoundingRect = null;
  final List<PlacedImage> placed_images = []; // Placed in the drawboard
  String selected_svg;
  num svg_id = 0;

  basedir_add([add_path]) {
    List pieces = window.location.href.split('/');
    pieces.removeLast();
    if(add_path != null)
      pieces.add(add_path);
    return pieces.join('/');
  }

  void main() {

    // Get initial size from css - http://stackoverflow.com/a/16113959/401041
    canvas = query("#canvas");
    canvas.width = int.parse(canvas.getComputedStyle().width.split('px')[0]);
    canvas.height = int.parse(canvas.getComputedStyle().height.split('px')[0]);

    // Cache it to make sure we don't trigger a reflow
    canvasBoundingRect = canvas.getBoundingClientRect();

    HttpRequest.getString(basedir_add("toolbox.txt")).then(load_default_svgs);

    canvas.onClick.listen(canvas_OnClick);
    canvas.onMouseMove.listen(canvas_OnMouseMove);
    canvas.onMouseOut.listen(canvas_OnMouseOut);
    canvas.onMouseWheel.listen(canvas_OnMouseWheel);
  }

  void load_default_svgs(String svgs) {
    for(var svg_name in svgs.split('\n')) {
      String svg_url = basedir_add("clipart/$svg_name");
      HttpRequest.getString(svg_url).then(add_svg_to_pallete);
    }
  }

  void add_svg_to_pallete(String svg) {
    SvgElement new_button = new SvgElement.svg(svg);

    String svg_width = new_button.attributes['width'];
    String svg_height = new_button.attributes['height'];

    // Some svgs use "pt" units which are not properly parsed
    svg_width = svg_width.replaceAll("pt", '');
    svg_height = svg_height.replaceAll("pt", '');

    num width = 50;
    num height = 50;

    new_button.attributes['width'] = '$height';
    new_button.attributes['height'] = '$width';
    new_button.attributes['viewBox'] = '0 0 $svg_width $svg_height';
    new_button.onClick.listen(toolbutton_OnClick);
    new_button.id = 'svg_toolbutton_${++svg_id}';
    query("#toolbar").children.add(new_button);
  }

  void toolbutton_OnClick(MouseEvent event) {
    SvgElement currentTarget = event.currentTarget;
    SvgElement svg_element = currentTarget.clone(true);
    var viewbox = svg_element.attributes['viewBox'];
    num width, height;
    num view_height = double.parse(viewbox.split(" ")[2]);
    num view_width = double.parse(viewbox.split(" ")[3]);
    num ratio = view_height/view_width;
    // Keep aspect ratio
    if(view_width > view_height) {
      width = 100;
      height = (width/ratio).floor();
    } else {
      height = 100;
      width = (height*ratio).floor();
    }
    svg_element.attributes['width'] = '$width';
    svg_element.attributes['height'] = '$height';
    active_toolbutton = new CanvasElement();
    active_toolbutton.width = width;
    active_toolbutton.height = height;
    var options = js.map({ 'ignoreMouse:': true,
      'ignoreAnimation': true,
      'ignoreDimensions': true});
    js.context.canvg(active_toolbutton, svg_element.outerHtml, options);
  }

  void canvas_OnMouseMove(MouseEvent event) {
    mouseX = event.clientX - canvasBoundingRect.left;
    mouseY = event.clientY - canvasBoundingRect.top;
    window.requestAnimationFrame(draw);
  }

  void canvas_OnMouseOut(MouseEvent event) {
    active_toolbutton = null;
    window.requestAnimationFrame(draw);
  }


  void canvas_OnClick(MouseEvent event) {
    if(active_toolbutton == null)
      active_toolbutton = prev_active_toolbutton;
    if(active_toolbutton != null) {
      final placeX = mouseX - active_toolbutton.width/2;
      final placeY = mouseY - active_toolbutton.height/2;
      placed_images.add(new PlacedImage(active_toolbutton, placeX, placeY));
      prev_active_toolbutton = active_toolbutton;
      window.requestAnimationFrame(draw);
    }
  }

  void canvas_OnMouseWheel(WheelEvent event)  {
    int change;
    int delta = event.deltaY;
    if(active_toolbutton == null)
      return;
    if(delta > 0)
      change = 1;
    else
       change = -1;
    var viewbox = active_toolbutton.attributes['viewBox'];
    num width, height;
    num view_height = double.parse(viewbox.split(" ")[2]);
    num view_width = double.parse(viewbox.split(" ")[3]);
    num ratio = view_height/view_width;
    // Keep aspect ratio
    if(view_width > view_height) {
      width = view_width + change;
      height = (width/ratio).floor();
    } else {
      height = view_height + change;
      width = (height*ratio).floor();
    }
    active_toolbutton.attributes['width'] = '$width';
    active_toolbutton.attributes['height'] = '$height';
  }

  void draw(num _) {
    final CanvasRenderingContext2D context = canvas.context2d;
    context.clearRect(0, 0, canvas.width, canvas.height);

    // Draw all images already placed in the board
    placed_images.forEach((e) =>
      context.drawImage(e.img, e.x, e.y)
    );

    if(active_toolbutton != null) {
      final placeX = mouseX - active_toolbutton.width/2;
      final placeY = mouseY - active_toolbutton.height/2;
      if(mouseX != null && mouseY != null) {
        context.drawImage(active_toolbutton, placeX, placeY);
      }
    }
  }
}

void main() {
  new StickyboardApp().main();
}
