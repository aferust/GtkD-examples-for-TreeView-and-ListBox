module example1;

import std.stdio, std.conv, std.format;

import gtk.Widget, gdk.Event;
import gtk.Window, gtk.HeaderBar;
import gtk.Box;
import gtk.Label;
import gtk.Entry, gtk.EditableIF;
import gtk.Button, gtk.RadioButton;
import gtk.ListStore, gtk.TreeView, gtk.TreeModelIF, gtk.TreeModel, gtk.TreeSelection, gtk.CellRendererText,
    gtk.CellRendererToggle, gtk.TreePath, gtk.TreeIter, gtk.TreeViewColumn;
import gobject.Value;

import arsd.sqlite;

import helpers;

class Ornek1 : Window {
    HeaderBar headerBar;

    Button but1, but2, but3;
    RadioButton opt_by_email;
    RadioButton opt_by_name;
    Entry entry1;

    ListStore listStore;
    TreeIter iter;
    
    this(){
        super("TreeView");

        headerBar = new HeaderBar();
        with (headerBar) {
            setTitle("TreeView example");
            setShowCloseButton(true);
            setHasSubtitle(false);
        }

        setTitlebar(headerBar);
        setDefaultSize(400, 200);
        setBorderWidth(5);

        but1 = new Button("Add new");
        but3 = new Button("Delete selected rows");

        listStore = new ListStore([GType.STRING, GType.STRING, GType.STRING, GType.STRING, GType.STRING, GType.BOOLEAN]);
        
        TreeView view = new TreeView(listStore);
        
        TreeSelection sel = view.getSelection();

        int cur_id = -1;
        sel.addOnChanged((selection){
                TreeModelIF model;
                TreeIter it;
                
                bool _is_set = selection.getSelected(model, it);
                iter = it;
                if(_is_set){
                    Value col0 = model.getValue(it, 0);
                    
                    
                    cur_id = col0.getString().to!int;
                    
                    writefln("selected: %d\n", cur_id);
                }

        });


        updateListStoreFromDb();

        auto cellId = new CellRendererText ();
        cellId.setSensitive(false);

        auto cell = new CellRendererText ();
        cell.setSensitive(true);
        cell.setProperty("editable", true);

        TreePath path_to_edit;
		TreeViewColumn column_to_edit;

        view.addOnCursorChanged((model){
            view.getCursor(path_to_edit, column_to_edit);
        });

        cell.addOnEdited(delegate void(string path, string text, CellRendererText x){
            int cid = column_to_edit.getSortColumnId;
            
            Value valId;
            iter = sel.getSelected();
            valId = listStore.getValue (iter, 0);
            if(valId.getString.to!int == -1) return; // do not modify the dummy row.
            
            final switch (cid) {
            /* case 0 is skipped.*/
            case 1:
                listStore.setValue(iter, cid, text);
                break;
            case 2:
                listStore.setValue(iter, cid, text);
                break;
            case 3:
                listStore.setValue(iter, cid, text);
                break;
            case 4:
                listStore.setValue(iter, cid, text);
                break;
            }

            updateCellOnDb(cid, valId.getString, text);
        });

        auto cellToggle = new CellRendererToggle();
        cellToggle.setActivatable(true);
        cellToggle.addOnToggled(delegate void(string path, CellRendererToggle t){
            TreePath treePath = new TreePath(path);
            TreeIter itr = new TreeIter;
            listStore.getIter(itr, treePath);
            listStore.setValue(itr, 5, !cellToggle.getActive());

        });

        TreeViewColumn id_col = new TreeViewColumn("id", cellId, "text", 0);
        TreeViewColumn email_col = new TreeViewColumn("E-mail", cell, "text", 1);
        TreeViewColumn name_col = new TreeViewColumn("Name", cell, "text", 2);
        TreeViewColumn age_col = new TreeViewColumn("Age", cell, "text", 3);
        TreeViewColumn gender_col = new TreeViewColumn("Gender", cell, "text", 4);
        TreeViewColumn tog_col = new TreeViewColumn ();

        tog_col.setTitle("Selection");
        tog_col.packStart(cellToggle, false);
        tog_col.addAttribute (cellToggle, "active", 5);

        id_col.setSortColumnId(0);
        email_col.setSortColumnId(1);
        name_col.setSortColumnId(2);
        age_col.setSortColumnId(3);
        gender_col.setSortColumnId(4);
        
        view.insertColumn(id_col, -1);
        view.insertColumn(email_col, -1);
        view.insertColumn(name_col, -1);
        view.insertColumn(age_col, -1);
        view.insertColumn(gender_col, -1);
        view.insertColumn(tog_col, -1);

        auto vbox1 = new Box(GtkOrientation.VERTICAL, 5);

        but1.addOnReleased(delegate void(Button b){
            auto db = new Sqlite("file.db");
            string sql = "INSERT INTO User (email, name, age, gender) VALUES ('empty', 'empty', 0, 0);";
            db.query(sql);

            auto last_id = db.lastInsertId();
            
            listStore.append (iter);
            listStore.set (iter, [0, 1, 2, 3, 4], [last_id.to!string, "empty", "empty", "0", "0"]);
            removeDummyIfAnyRecordExist();
        });

        but3.addOnReleased(delegate void(Button b){ //delete selected rows
                
                TreeIter it;
                listStore.getIterFirst(it);
                bool hasNext = true;

                do {
                    Value valSelected = listStore.getValue(it, 5);
                    bool is_selected = valSelected.getBoolean;

                    if(is_selected){
                        
                        auto nrows = listStore.iterNChildren(null);
                        auto id = listStore.getValue(it, 0).getString().to!int;
                        delete_row(id);
                        if(nrows == 1 )
                            addDummyRow();
                        
                        hasNext = listStore.remove(it);
                       
                    } else
                        hasNext = listStore.iterNext(it);

                } while (hasNext);
            });

        Box hbox = new Box(GtkOrientation.HORIZONTAL, 5);
        Label lb = new Label("Search by");
        opt_by_email = new RadioButton("email");
        opt_by_name= new RadioButton("name");
        opt_by_name.setGroup(opt_by_email.getGroup());
        auto opGroup = new Box(GtkOrientation.HORIZONTAL, 5);
        opGroup.add(opt_by_email);
        opGroup.add(opt_by_name);
        hbox.add(lb);
        hbox.add(opGroup);

        opt_by_name.setActive(true);

        entry1 = new Entry();
        entry1.addOnChanged(delegate void(EditableIF entry){
            string search_str = entry1.getText();
            bool em_active = opt_by_email.getActive();
            updateListStoreOnSearch(search_str, em_active?"email":"name");
        });

        vbox1.add(but1);
        vbox1.add(but3);
        vbox1.add(hbox);
        vbox1.add(entry1);
        vbox1.add(view);

        add(vbox1);

        showAll();
    }

    void updateListStoreFromDb(){
        auto db = new Sqlite("file.db");
        string query = "SELECT * FROM User";
        listStore.clear();

        int count = 0;
        foreach(values; db.query(query)) {
            listStore.append (iter);
            listStore.set (iter, [0, 1, 2, 3, 4], [values[0], values[1], values[2], values[3], values[4]]);
            count ++;
        }

        if(count == 0)
            addDummyRow();

    }

    void addDummyRow(){ // empty store causes crashes, so add one dummy row
        listStore.append (iter);
        listStore.set (iter, [0, 1, 2, 3, 4], ["-1", "no record", "no record", "no record", "no record"]);
    }

    void removeDummyIfAnyRecordExist(){

        foreach (TreeIter iter; TreeIterRange(listStore)) {
            Value valId = listStore.getValue (iter, 0);
            int id = valId.getString.to!int;
            if(id == -1) listStore.remove(iter);
        }
    }

    void delete_row(int id){
        auto db = new Sqlite("file.db");

        string sql = format("DELETE FROM User WHERE id = %d;", id);
        db.query(sql);
    }

    void updateCellOnDb(int cid, string curId, string text){
        auto db = new Sqlite("file.db");

        immutable string[5] fields = [
            "id",
            "email",
            "name",
            "age",
            "gender"
        ];

        string field = fields[cid];

        string sql = format("UPDATE User SET %s = '%s' WHERE id = %s;", field, text, curId);
        db.query(sql);
    }

    void updateListStoreOnSearch(string search_str, string field_name){
        listStore.clear();
        auto db = new Sqlite("file.db");
        
        int count = 0;
        foreach(values; db.query(format("SELECT * FROM User WHERE %s LIKE '%%%s%%'", field_name, search_str))) {
            listStore.append (iter);
            listStore.set (iter, [0, 1, 2, 3, 4], [values[0], values[1], values[2], values[3], values[4]]);
            count ++;
        }
        if(count == 0)
            addDummyRow();

    }
}