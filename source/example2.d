module example2;

import core.stdc.stdlib;
import std.stdio, std.conv, std.format;

import std.functional;
import std.experimental.logger;

import gtk.Widget, gdk.Event;
import gtk.Window, gtk.HeaderBar;
import gtk.Label, gtk.Entry, gtk.Button, gtk.SpinButton, gtk.Switch, gtk.Box, gtk.ComboBoxText;
import gtk.SearchEntry, gtk.EditableIF, gtk.RadioButton;
import gtk.ListBox, gtk.ListBoxRow, gtk.Frame, gtk.Image;
import gobject.ParamSpec, gobject.ObjectG;

import arsd.sqlite;

import helpers: getMyDObject;

// static immutable string[3] genders = ["Male", "Female", "Not specified"];

class Ornek2: Window {
    HeaderBar headerBar;

    Box vbox1;
    Label labelId;
    Label labelEmail;
    Label labelName;
    Label labelAge;
    Label labelGender;
    Label labelDelete;
    Label labelExpand;

    ListBox listbox;
    Box fake_header;
    Box mcontent;

    RadioButton opt_by_email;
    RadioButton opt_by_name;
    
    this(){
        
        super("Örnek 2");

        headerBar = new HeaderBar();
        with (headerBar) {
            setTitle("ListBox example");
            setShowCloseButton(true);
            setHasSubtitle(false);
        }

        setTitlebar(headerBar);
        
        vbox1 = new Box(GtkOrientation.VERTICAL, 5);
        auto hbox1 = new Box(GtkOrientation.HORIZONTAL, 5);
        
        auto addBut = new Button("Add new");

        addBut.addOnClicked((Button aux){
            addRecord();
        });
        
        auto swGrouper = new Box(GtkOrientation.HORIZONTAL, 5);
        auto sw = new Switch();
        
        extern (C) int sortList1(GtkListBoxRow* _row1, GtkListBoxRow* _row2, void* userData){
            auto ctx = cast(Ornek2)userData;
            
            auto row1 = cast(ListBoxRowWithData)getMyDObject!ListBoxRow(_row1);
            auto row2 = cast(ListBoxRowWithData)getMyDObject!ListBoxRow(_row2);

            if(row1.id < row2.id) return 1;
            return 0;
        }
        extern (C) int sortList2(GtkListBoxRow* _row1, GtkListBoxRow* _row2, void* userData){
            auto ctx = cast(Ornek2)userData;
            
            auto row1 = cast(ListBoxRowWithData)getMyDObject!ListBoxRow(_row1);
            auto row2 = cast(ListBoxRowWithData)getMyDObject!ListBoxRow(_row2);

            if(row1.id > row2.id) return 1;
            return 0;
        }

        sw.addOnNotify(delegate void(ParamSpec param, ObjectG ob){
            if(sw.getActive()){
                listbox.setSortFunc(&sortList1, cast(void*)this, &_destroy);
            } else {
                listbox.setSortFunc(&sortList2, cast(void*)this, &_destroy);
            }
        }, "active");

        swGrouper.add(new Label("Reverse order"));
        swGrouper.add(sw);
        
        hbox1.packStart(swGrouper, false, false, 5);
        hbox1.packEnd(addBut, false, false, 5);
        
        vbox1.add(hbox1);

        ///////////// search bar

        auto hbox2 = new Box(GtkOrientation.HORIZONTAL, 5);

        auto searchBox = new SearchEntry();
        hbox2.packStart(searchBox, true, true, 5);

        vbox1.add(hbox2);

        Label lb = new Label("Search by");
        opt_by_email = new RadioButton("email");
        opt_by_name= new RadioButton("name");
        opt_by_name.setGroup(opt_by_email.getGroup());
        auto opGroup = new Box(GtkOrientation.HORIZONTAL, 5);
        opGroup.add(opt_by_email);
        opGroup.add(opt_by_name);
        opt_by_name.setActive(true);
        hbox2.add(lb);
        hbox2.add(opGroup);

        searchBox.addOnChanged(delegate void(EditableIF _ ){
            string search_str = searchBox.getText();
            bool em_active = opt_by_email.getActive();
            populateOnSearch(search_str, em_active?"email":"name");
        });
        //////////////

        listbox = new ListBox;
        listbox.setSelectionMode(GtkSelectionMode.NONE);

        populateList();
        makeHeader();
        
        mcontent = new Box(GtkOrientation.VERTICAL, 3);
        vbox1.add(mcontent);

        vbox1.add(listbox);
        
        mcontent.packStart(fake_header, false, true, 0);
        mcontent.reorderChild(fake_header, 0);
        mcontent.showAll();
        
        listbox.showAll();

        add(vbox1);

        showAll();
    }

    void populateList(){
        auto db = new Sqlite("file.db");
        string query = "SELECT * FROM User";
        
        foreach(values; db.query(query)) {
            auto a = new ListBoxRowWithData(
                values[0].to!int,
                values[1],
                values[2],
                values[3].to!int,
                values[4].to!int, this);
            listbox.add(a);
        }

    }

    void populateOnSearch(string search_str, string field_name){
        clearListbox();
        
        auto db = new Sqlite("file.db");
        
        foreach(values; db.query(format("SELECT * FROM User WHERE %s LIKE '%%%s%%'", field_name, search_str))) {
            int id = values[0].to!int;
            string email = values[1];
            string name = values[2];
            int age = values[3].to!int;
            int gender = values[4].to!int;

            auto row = new ListBoxRowWithData(id, email, name, age, gender, this);
            listbox.add(row);
        }
        
        listbox.showAll();			
    }

    void clearListbox(int id = -1){
        auto allkids = listbox.getChildren().toArray!ListBoxRow;
        if(id == -1){
            foreach (entry; allkids){
                listbox.remove(entry);
            }
        }else{
            foreach (entry; allkids){
                if((cast(ListBoxRowWithData)entry).id == id) listbox.remove(entry);
            }
        }
        
    }


    void addRecord(){
        auto db = new Sqlite("file.db");
        string sql = "INSERT INTO User (email, name, age, gender) VALUES ('empty', 'empty', 0, 0);";
        db.query(sql);
        auto last_id = db.lastInsertId();

        auto a = new ListBoxRowWithData(last_id, "empty", "empty", 0, 0, this);
        listbox.add(cast(ListBoxRow)a);
    }

    void updateField(T)(int cid, string field, T _value){
        auto db = new Sqlite("file.db");

        static if (is(T == string)){
            string value = _value;
        }
        else static if (is(T == int)){
            string value = _value.to!string;
        }

        string sql = format("UPDATE User SET %s = '%s' WHERE id = %d;", field, value, cid);
        db.query(sql);
    }

    void makeHeader(){
        if(fake_header is null){
            fake_header = new Box(Orientation.HORIZONTAL, 0);
        }

        listbox.setHeaderFunc(&upHeader, cast(void*)this,  &_destroy);
    }

}

extern(C) void _destroy(void* data) {}

extern(C) void upHeader(GtkListBoxRow* _row, GtkListBoxRow* before, void* userData){

    auto ctx = cast(Ornek2)userData;
    auto row = cast(ListBoxRowWithData)getMyDObject!ListBoxRow(_row);

    if(row.getIndex == 0){
        auto id = new Label("id");
        auto em = new Label("email");
        auto nm = new Label("name");
        auto ag = new Label("age");
        auto gn = new Label("gender");
        auto dl = new Label("delete");
        auto ex = new Label("expand");
        
        ctx.fake_header.packStart (id, true, true, 0);
        ctx.fake_header.packStart (em, true, true, 0);
        ctx.fake_header.packStart (nm, true, true, 0);
        ctx.fake_header.packStart (ag, true, true, 0);
        ctx.fake_header.packStart (gn, true, true, 0);
        ctx.fake_header.packStart (dl, true, true, 0);
        ctx.fake_header.packStart (ex, false, false, 0);

        ctx.fake_header.addOnRealize(delegate void(Widget wid){
            
            row.init_widths();
            
            id.setSizeRequest(ListBoxRowWithData.id_width, -1);
            em.setSizeRequest(ListBoxRowWithData.em_width, -1);
            nm.setSizeRequest(ListBoxRowWithData.nm_width, -1);
            ag.setSizeRequest(ListBoxRowWithData.ag_width, -1);
            gn.setSizeRequest(ListBoxRowWithData.gn_width, -1);
            dl.setSizeRequest(ListBoxRowWithData.dl_width, -1);
            ex.setSizeRequest(ListBoxRowWithData.ex_width, -1);

        });
    }else{
        row.setHeader(null);
    }
}

class ListBoxRowWithData: ListBoxRow {

    int id;
    int age;
    int gender;
    string email;
    string uname;
    Ornek2 ctx;
   
    Label label_id;
    Entry entry_email;
    Entry entry_name;
    SpinButton entry_age;
    ComboBoxText entry_gender;
    Button but_del;
    Button expand_but;

    bool eXpanded = false;
    
    static int id_width;
    static int em_width;
    static int nm_width;
    static int ag_width;
    static int gn_width;
    static int dl_width;
    static int ex_width;

    
    this(int id, string email, string name, int age, int gender, Ornek2 ctx){
        super();
        this.id = id; this.email = email; this.uname = name; this.age = age; this.gender = gender; this.ctx = ctx;
        
        label_id = new Label(id.to!string); label_id.setSizeRequest(100, -1);
        entry_email = new Entry(email); entry_email.setSizeRequest(100, -1);
        entry_name = new Entry(name); entry_name.setSizeRequest(100, -1);
        entry_age = new SpinButton(0, 150, 1); entry_age.setSizeRequest(100, -1);
        entry_age.setValue(age);
        entry_gender = new ComboBoxText();
        entry_gender.appendText ("Male");
        entry_gender.appendText ("Female");
        entry_gender.appendText ("Not Specified");
        entry_gender.setActive(gender);

        Box expand_box = new Box(Orientation.HORIZONTAL, 0);
        auto expand_label = new Label("Additional details of id:%d can place here!".format(id));
        auto frame = new Frame("Details here");
        frame.add(expand_label);
        expand_box.packStart (frame, true, true, 0);
        expand_but = new Button(StockID.GO_DOWN, true);
        expand_but.setImage(new Image("go-down", IconSize.BUTTON));

        entry_email.addOnChanged((_){
            ctx.updateField(id, "email", entry_email.getText());
        });

        entry_name.addOnChanged((_){
            ctx.updateField(id, "name", entry_name.getText());
        });

        entry_age.addOnChanged((_){
            ctx.updateField(id, "age", entry_age.getText().to!string);
        });

        entry_gender.addOnChanged(delegate void(ComboBoxText _){
            ctx.updateField(id, "gender", entry_gender.getActive());
        });


        but_del = new Button("delete");
        but_del.addOnClicked(delegate void(Button _){
            delete_row(id);
            ctx.listbox.remove(this);
        });

        Box row_box = new Box (Orientation.VERTICAL, 0);
        Box inner_box = new Box (Orientation.HORIZONTAL, 0);
        inner_box.packStart (label_id, true, true, 0);
        inner_box.packStart (entry_email, true, true, 0);
        inner_box.packStart (entry_name, true, true, 0);
        inner_box.packStart (entry_age, true, true, 0);
        inner_box.packStart (entry_gender, true, true, 0);
        inner_box.packStart (but_del, true, true, 0);
        inner_box.packStart (expand_but, false, false, 0);

        row_box.add(inner_box);
        this.add(row_box);

        expand_but.addOnClicked(delegate void(Button _){
            eXpanded = !eXpanded;
            if(eXpanded == true){
                row_box.add(expand_box);
                expand_but.setImage(new Image("go-up", IconSize.BUTTON));
                row_box.showAll();
            }else{
                row_box.remove(expand_box);
                expand_but.setImage(new Image("go-down", IconSize.BUTTON));
            }
        });

        showAll();
    }

    void init_widths(){
        if(id_width == 0){
            id_width = label_id.getAllocatedWidth() > id_width ? label_id.getAllocatedWidth(): id_width;
            em_width = entry_email.getAllocatedWidth() > em_width ? entry_email.getAllocatedWidth(): em_width;
            nm_width = entry_name.getAllocatedWidth() > nm_width ? entry_name.getAllocatedWidth(): nm_width;
            ag_width = entry_age.getAllocatedWidth() > ag_width ? entry_age.getAllocatedWidth(): ag_width;
            gn_width = entry_gender.getAllocatedWidth() > gn_width ? entry_gender.getAllocatedWidth(): gn_width;
            dl_width = but_del.getAllocatedWidth() > dl_width ? but_del.getAllocatedWidth(): dl_width;
            ex_width = expand_but.getAllocatedWidth() > ex_width ? expand_but.getAllocatedWidth(): ex_width;
        }
    }
    
}

    void delete_row(int id){
        auto db = new Sqlite("file.db");

        string sql = format("DELETE FROM User WHERE id = %d;", id);
        db.query(sql);
    }