/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package watchers;


import flash.display.*;
import flash.events.*;
import flash.net.*;
import flash.text.*;
import flash.utils.*;
import interpreter.Interpreter;
import scratch.ScratchObj;
import translation.Translator;
import util.JSON;
import uiwidgets.*;

class ListWatcher extends Sprite
{

	private var titleFont : TextFormat = new TextFormat(CSS.font, 12, 0, true);
	private var cellNumFont : TextFormat = new TextFormat(CSS.font, 11, 0, false);
	private static inline var SCROLLBAR_W : Int = 10;

	public var listName : String = "";
	public var target : ScratchObj;  // the ScratchObj that owns this list  
	public var contents : Array<Dynamic> = [];
	public var isPersistent : Bool = false;

	private var frame : ResizeableFrame;
	private var title : TextField;
	private var elementCount : TextField;
	private var cellPane : Sprite;
	private var scrollbar : Scrollbar;
	private var addItemButton : IconButton;

	private var firstVisibleIndex : Int;
	private var visibleCells : Array<Dynamic> = [];
	private var visibleCellNums : Array<Dynamic> = [];
	private var insertionIndex : Int = -1;  // where to add an item; -1 means to add it at the end  

	private var cellPool : Array<Dynamic> = [];  // recycled cells  
	private var cellNumPool : Array<Dynamic> = [];  // recycled cell numbers  
	private var tempCellNum : TextField;  // used to compute maximum cell number width  

	private var lastAccess : Array<Int> = new Array<Int>();
	private var lastActiveIndex : Int;
	private var contentsChanged : Bool;
	private var isIdle : Bool;
	private var limitedView : Bool;

	public function new(listName : String = "List Title", contents : Array<Dynamic> = null, target : ScratchObj = null, limitView : Bool = false)
	{
		super();
		this.listName = listName;
		this.target = target;
		this.contents = ((contents == null)) ? [] : contents;
		limitedView = limitView;

		frame = new ResizeableFrame(0x949191, 0xC1C4C7, 14, false, 2);
		frame.setWidthHeight(50, 100);
		frame.showResizer();
		frame.minWidth = 80;
		frame.minHeight = 62;
		addChild(frame);

		title = createTextField(listName, titleFont);
		frame.addChild(title);

		cellPane = new Sprite();
		cellPane.mask = new Shape();
		cellPane.addChild(cellPane.mask);
		addChild(cellPane);

		scrollbar = new Scrollbar(10, 10, scrollToFraction);
		addChild(scrollbar);

		addItemButton = new IconButton(addItem, "addItem");
		addChild(addItemButton);

		elementCount = createTextField(Translator.map("length") + ": 0", cellNumFont);
		frame.addChild(elementCount);

		setWidthHeight(100, 200);
		addEventListener(flash.events.FocusEvent.FOCUS_IN, gotFocus);
		addEventListener(flash.events.FocusEvent.FOCUS_OUT, lostFocus);
	}

	public static function strings() : Array<Dynamic>{
		return [
		"length", "import", "export", "hide", 
		"Which column do you want to import"];
	}

	public function toggleLimitedView(limitView : Bool) : Void{
		limitedView = limitView;
	}
	public function updateTitleAndContents() : Void{
		// Called when opening a project.
		updateTitle();
		scrollToIndex(0);
	}

	public function updateTranslation() : Void{updateElementCount();
	}

	/* Dragging */

	public function objToGrab(evt : MouseEvent) : ListWatcher{return this;
	}  // allow dragging  

	/* Menu */

	public function menu(evt : MouseEvent) : Menu{
		var m : Menu = new Menu();
		m.addItem("import", importList);
		m.addItem("export", exportList);
		m.addLine();
		m.addItem("hide", hide);
		return m;
	}

	private function importList() : Void{
		// Prompt user for a file name and import that file.
		// Each line of the file becomes a list item.
		function fileLoaded(event : Event) : Void{
			var file : FileReference = cast((event.target), FileReference);
			var s : String = file.data.readUTFBytes(file.data.length);
			importLines(removeTrailingEmptyLines(s.split(new EReg('\\r\\n|[\\r\\n]', ""))));
		};

		Scratch.loadSingleFile(fileLoaded);
	}

	private function exportList() : Void{
		var file : FileReference = new FileReference();
		var s : String = contents.join("\n") + "\n";
		file.save(s, listName + ".txt");
	}

	private function hide() : Void{
		visible = false;
		Scratch.app.updatePalette(false);
	}

	// -----------------------------
	// Visual feedback for list changes
	//------------------------------

	private function removeTrailingEmptyLines(lines : Array<Dynamic>) : Array<Dynamic>{
		while (lines.length != 0 && !lines[lines.length - 1])lines.pop();
		return lines;
	}

	private function importLines(lines : Array<Dynamic>) : Void{
		var delimiter : String = guessDelimiter(lines);
		if (delimiter == null) {  // single column (or empty)  
			contents = lines;
			scrollToIndex(0);
			return;
		}
		var columnCount : Int = lines[0].split(delimiter).length;
		function gotColumn(s : String) : Void{
			var n : Float = Std.parseInt(s);
			if (Math.isNaN(n) || (n < 1) || (n > columnCount))                 contents = lines
			else contents = extractColumn(Std.int(n), lines, delimiter);
			scrollToIndex(0);
		};
		DialogBox.ask(
				Translator.map("Which column do you want to import") + "(1-" + columnCount + ")?",
				"1", Scratch.app.stage, gotColumn);
	}

	private function guessDelimiter(lines : Array<Dynamic>) : String{
		// Guess the delimiter used to separate the fields in multicolumn data.
		// Return the delimiter or null if the data is not multicolumn.
		// Note: Assume we've found the right delimiter if it splits three
		// lines into the same number (greater than 1) of fields.

		if (lines.length == 0)             return null;

		for (d/* AS3HX WARNING could not determine type for var: d exp: EArrayDecl([EConst(CString(,)),EConst(CString(\t))]) type: null */ in [",", "\t"]){
			var count1 : Int = lines[0].split(d).length;
			var count2 : Int = lines[Math.floor(lines.length / 2)].split(d).length;
			var count3 : Int = lines[lines.length - 1].split(d).length;
			if ((count1 > 1) && (count1 == count2) && (count1 == count3))                 return d;
		}
		return null;
	}

	private function extractColumn(n : Int, lines : Array<Dynamic>, delimiter : String) : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (s in lines){
			var cols : Array<Dynamic> = s.split(delimiter);
			result.push(((n <= cols.length)) ? cols[n - 1] : "");
		}
		return result;
	}

	// -----------------------------
	// Visual feedback for list changes
	//------------------------------

	public function updateWatcher(i : Int, readOnly : Bool, interp : Interpreter) : Void{
		// Called by list primitives. Record access to entry at i and whether list contents have changed.
		// readOnly should be true for read operations, false for operations that change the list.
		// Note: To reduce the cost of list operations, this function merely records changes,
		// leaving the more time-consuming work of updating the visual feedback to step(), which
		// is called only once per frame.
		isIdle = false;
		if (!readOnly)             contentsChanged = true;
		if (parent == null)             visible = false;
		if (!visible)             return;
		adjustLastAccessSize();
		if ((i < 1) || (i > lastAccess.length))             return;
		lastAccess[i - 1] = Math.round(haxe.Timer.stamp() * 1000);
		lastActiveIndex = i - 1;
		interp.redraw();
	}

	public function prepareToShow() : Void{
		// Called before showing a list that has been hidden to update its contents.
		updateTitle();
		contentsChanged = true;
		isIdle = false;
		step();
	}

	public function step() : Void{
		// Update index highlights and contents if they have changed.
		if (isIdle)             return;
		if (contentsChanged) {
			updateContents();
			updateScrollbar();
			contentsChanged = false;
		}
		if (contents.length == 0) {
			isIdle = true;
			return;
		}
		ensureVisible();
		updateIndexHighlights();
	}

	private function ensureVisible() : Void{
		var i : Int = Std.int(Math.max(0, Math.min(lastActiveIndex, contents.length - 1)));
		if ((firstVisibleIndex <= i) && (i < (firstVisibleIndex + visibleCells.length))) {
			return;
		}
		firstVisibleIndex = i;
		updateContents();
		updateScrollbar();
	}

	private function updateIndexHighlights() : Void{
		// Highlight the cell number of all recently accessed cells currently visible.
		var fadeoutMSecs : Int = 800;
		adjustLastAccessSize();
		var now : Int = Math.round(haxe.Timer.stamp() * 1000);
		isIdle = true;  // try to be idle; set to false if any non-zero lastAccess value is found  
		for (i in 0...visibleCellNums.length){
			var lastAccessTime : Int = lastAccess[firstVisibleIndex + i];
			if (lastAccessTime > 0) {
				isIdle = false;
				var msecsSinceAccess : Int = now - lastAccessTime;
				if (msecsSinceAccess < fadeoutMSecs) {
					// Animate from yellow to black over fadeoutMSecs.
					var gray : Int = Std.int(255 * ((fadeoutMSecs - msecsSinceAccess) / fadeoutMSecs));
					visibleCellNums[i].textColor = (gray << 16) | (gray << 8);
				}
				else {
					visibleCellNums[i].textColor = 0;  // black  
					lastAccess[firstVisibleIndex + i] = 0;
				}
			}
		}
	}

	private function adjustLastAccessSize() : Void{
		// Ensure that lastAccess is the same length as contents.
		if (lastAccess.length == contents.length)             return;
		if (lastAccess.length < contents.length) {
			lastAccess = lastAccess.concat(new Array<Int>());
		}
		else if (lastAccess.length > contents.length) {
			lastAccess = lastAccess.substring(0, contents.length);
		}
	}

	// -----------------------------
	// Add Item Button Support
	//------------------------------

	private function addItem(b : IconButton = null) : Void{
		// Called when addItemButton is clicked.
		if ((Std.is(root, Scratch)) && !(try cast(root, Scratch) catch(e:Dynamic) null).editMode)             return;
		if (insertionIndex < 0)             insertionIndex = contents.length;
		contents.splice(insertionIndex, 0, "");
		updateContents();
		updateScrollbar();
		selectCell(insertionIndex);
	}

	private function gotFocus(e : FocusEvent) : Void{
		// When the user clicks on a cell, it gets keyboard focus.
		// Record that list index for possibly inserting a new cell.
		// Note: focus is lost when the addItem button is clicked.
		var newFocus : DisplayObject = try cast(e.target, DisplayObject) catch(e:Dynamic) null;
		if (newFocus == null)             return;
		insertionIndex = -1;
		for (i in 0...visibleCells.length){
			if (visibleCells[i] == newFocus.parent) {
				insertionIndex = firstVisibleIndex + i + 1;
				return;
			}
		}
	}

	private function lostFocus(e : FocusEvent) : Void{
		// If another object is getting focus, clear insertionIndex.
		if (e.relatedObject != null)             insertionIndex = -1;
	}

	// -----------------------------
	// Delete Item Button Support
	//------------------------------

	private function deleteItem(b : IconButton) : Void{
		var cell : ListCell = try cast(b.lastEvent.target.parent, ListCell) catch(e:Dynamic) null;
		if (cell == null)             return;
		for (i in 0...visibleCells.length){
			var c : ListCell = visibleCells[i];
			if (c == cell) {
				var j : Int = firstVisibleIndex + i;
				contents.splice(j, 1);
				if (j == contents.length && visibleCells.length == 1) {
					scrollToIndex(j - 1);
				}
				else {
					updateContents();
					updateScrollbar();
				}
				if (visibleCells.length != 0) {
					selectCell(Std.int(Math.min(j, contents.length - 1)));
				}
				return;
			}
		}
	}

	// -----------------------------
	// Layout
	//------------------------------

	public function setWidthHeight(w : Int, h : Int) : Void{
		frame.setWidthHeight(w, h);
		fixLayout();
	}

	public function fixLayout() : Void{
		// Called by ResizeableFrame, so must be public.
		title.x = Math.floor((frame.w - title.width) / 2);
		title.y = 2;

		elementCount.x = Math.floor((frame.w - elementCount.width) / 2);
		elementCount.y = frame.h - elementCount.height + 1;

		cellPane.x = 1;
		cellPane.y = 22;

		addItemButton.x = 2;
		addItemButton.y = frame.h - addItemButton.height - 2;

		var g : Graphics = (try cast(cellPane.mask, Shape) catch(e:Dynamic) null).graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, frame.w - 17, frame.h - 42);
		g.endFill();

		scrollbar.setWidthHeight(SCROLLBAR_W, Std.int(cellPane.mask.height));
		scrollbar.x = frame.w - SCROLLBAR_W - 2;
		scrollbar.y = 20;

		updateContents();
		updateScrollbar();
	}

	// -----------------------------
	// List contents layout and scrolling
	//------------------------------

	private function scrollToFraction(n : Float) : Void{
		var old : Int = firstVisibleIndex;
		n = Math.floor(n * contents.length);
		firstVisibleIndex = Std.int(Math.max(0, Math.min(n, contents.length - 1)));
		lastActiveIndex = firstVisibleIndex;
		if (firstVisibleIndex != old)             updateContents();
	}

	private function scrollToIndex(i : Int) : Void{
		var frac : Float = i / (contents.length - 1);
		firstVisibleIndex = -1;  // force scrollToFraction() to always update contents  
		scrollToFraction(frac);
		updateScrollbar();
	}

	private function updateScrollbar() : Void{
		var frac : Float = (firstVisibleIndex - 1) / (contents.length - 1);
		scrollbar.update(frac, visibleCells.length / contents.length);
	}

	public function updateContents() : Void{
		//		var limitedCloudView:Boolean = isPersistent;
		//		if (limitedCloudView &&
		//			Scratch.app.isLoggedIn() && Scratch.app.editMode &&
		//			(Scratch.app.projectOwner == Scratch.app.userName)) {
		//				limitedCloudView = false; // only project owner can view cloud list contents
		//		}
		var isEditable : Bool = Scratch.app.editMode && !limitedView;
		updateElementCount();
		removeAllCells();
		visibleCells = [];
		visibleCellNums = [];
		var visibleHeight : Int = Std.int(cellPane.height);
		var cellNumRight : Int = cellNumWidth() + 14;
		var cellX : Int = cellNumRight;
		var cellW : Int = Std.int(cellPane.width - cellX - 1);
		var nextY : Int = 0;
		for (i in firstVisibleIndex...contents.length){
			var s : String = Watcher.formatValue(contents[i]);
			if (limitedView && (s.length > 8))                 s = s.substring(0, 8) + "...";
			var cell : ListCell = allocateCell(s, cellW);
			cell.x = cellX;
			cell.y = nextY;
			cell.setEditable(isEditable);
			visibleCells.push(cell);
			cellPane.addChild(cell);

			var cellNum : TextField = allocateCellNum(Std.string(i + 1));
			cellNum.x = cellNumRight - cellNum.width - 3;
			cellNum.y = nextY + Std.int((cell.height - cellNum.height) / 2);
			cellNum.textColor = 0;
			visibleCellNums.push(cellNum);
			cellPane.addChild(cellNum);

			nextY += Std.int(cell.height - 1);
			if (nextY > visibleHeight)                 break;
		}

		if (contents.length == 0) {
			var tf : TextField = createTextField(Translator.map("(empty)"), cellNumFont);
			tf.x = (frame.w - SCROLLBAR_W - tf.textWidth) / 2;
			tf.y = (visibleHeight - tf.textHeight) / 2;
			cellPane.addChild(tf);
		}
	}

	private function cellNumWidth() : Int{
		// Return the estimated maximum cell number width. We assume that a list
		// can display at most 20 elements, so we need enough width to display
		// firstVisibleIndex + 20. Take the log base 10 to get the number of digits
		// and measure the width of a textfield with that many zeros.
		if (tempCellNum == null)             tempCellNum = createTextField("", cellNumFont);
		var digitCount : Int = Std.int(Math.log(firstVisibleIndex + 20) / Math.log(10));
		tempCellNum.text = "000000000000000".substring(0, digitCount);
		return Std.int(tempCellNum.textWidth);
	}

	private function removeAllCells() : Void{
		// Remove all children except the mask. Recycle ListCells and TextFields.
		while (cellPane.numChildren > 1){
			var o : DisplayObject = cellPane.getChildAt(1);
			if (Std.is(o, ListCell))                 cellPool.push(o);
			if (Std.is(o, TextField))                 cellNumPool.push(o);
			cellPane.removeChildAt(1);
		}
	}

	private function allocateCell(s : String, width : Int) : ListCell{
		// Allocate a ListCell with the given contents and width.
		// Recycle one from the cell pool if possible.
		if (cellPool.length == 0)             return new ListCell(s, width, textChanged, keyPress, deleteItem);
		var result : ListCell = cellPool.pop();
		result.setText(s, width);
		return result;
	}

	private function allocateCellNum(s : String) : TextField{
		// Allocate a TextField for a cell number with the given contents.
		// Recycle one from the cell number pool if possible.
		if (cellNumPool.length == 0)             return createTextField(s, cellNumFont);
		var result : TextField = cellNumPool.pop();
		result.text = s;
		result.width = result.textWidth + 5;
		return result;
	}

	private function createTextField(s : String, format : TextFormat) : TextField{
		var tf : TextField = new TextField();
		tf.type = TextFieldType.DYNAMIC;  // not editable  
		tf.selectable = false;
		tf.defaultTextFormat = format;
		tf.text = s;
		tf.height = tf.textHeight + 5;
		tf.width = tf.textWidth + 5;
		return tf;
	}

	public function updateTitle() : Void{
		title.text = (((target == null) || (target.isStage))) ? listName : target.objName + ": " + listName;
		title.width = title.textWidth + 5;
		title.x = Math.floor((frame.w - title.width) / 2);
	}

	private function updateElementCount() : Void{
		elementCount.text = Translator.map("length") + ": " + contents.length;
		elementCount.width = elementCount.textWidth + 5;
		elementCount.x = Math.floor((frame.w - elementCount.width) / 2);
	}

	// -----------------------------
	// User Input (handle events for cell's TextField)
	//------------------------------

	private function textChanged(e : Event) : Void{
		// Triggered by editing the contents of a cell.
		// Copy the cell contents into the underlying list.
		var cellContents : TextField = try cast(e.target, TextField) catch(e:Dynamic) null;
		for (i in 0...visibleCells.length){
			var cell : ListCell = visibleCells[i];
			if (cell.tf == cellContents) {
				contents[firstVisibleIndex + i] = cellContents.text;
				return;
			}
		}
	}

	private function selectCell(i : Int, scroll : Bool = true) : Void{
		var j : Int = i - firstVisibleIndex;
		if (j >= 0 && j < visibleCells.length) {
			visibleCells[j].select();
			insertionIndex = i + 1;
		}
		else if (scroll) {
			scrollToIndex(i);
			selectCell(i, false);
		}
	}

	private function keyPress(e : KeyboardEvent) : Void{
		// Respond to a key press on a cell.
		if (e.keyCode == 13) {
			if (e.shiftKey)                 insertionIndex--;
			addItem();
			return;
		}
		if (contents.length < 2)             return;  // only one cell, and it's already selected  ;
		var direction : Int = 
		e.keyCode == (38) ? -1 : 
		e.keyCode == (40) ? 1 : 
		e.keyCode == (9) ? ((e.shiftKey) ? -1 : 1) : 0;
		if (direction == 0)             return;
		var cellContents : TextField = try cast(e.target, TextField) catch(e:Dynamic) null;
		for (i in 0...visibleCells.length){
			var cell : ListCell = visibleCells[i];
			if (cell.tf == cellContents) {
				selectCell((firstVisibleIndex + i + direction + contents.length) % contents.length);
				return;
			}
		}
	}

	// -----------------------------
	// Saving
	//------------------------------

	public function writeJSON(json : util.JSON) : Void{
		json.writeKeyValue("listName", listName);
		json.writeKeyValue("contents", contents);
		json.writeKeyValue("isPersistent", isPersistent);
		json.writeKeyValue("x", x);
		json.writeKeyValue("y", y);
		json.writeKeyValue("width", width);
		json.writeKeyValue("height", height);
		json.writeKeyValue("visible", visible && (parent != null));
	}

	public function readJSON(obj : Dynamic) : Void{
		listName = obj.listName;
		contents = obj.contents;
		isPersistent = ((obj.isPersistent == null)) ? false : obj.isPersistent;  // handle old projects gracefully  
		x = obj.x;
		y = obj.y;
		setWidthHeight(obj.width, obj.height);
		visible = obj.visible;
		updateTitleAndContents();
	}
}
