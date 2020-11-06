module appwindow;

import app;

import core.stdc.stdlib;

import std.functional;
import std.experimental.logger;

import gtk.Widget, gdk.Event;
import gtk.ApplicationWindow, gtk.HeaderBar, gtk.Image, gtk.Fixed;
import gtk.Box;
import gtk.Label;
import gtk.Button;
import gtk.Statusbar, gtk.Separator;

import example1, example2;

class AppWindow: ApplicationWindow {
    HeaderBar headerBar;

    Fixed vbox1;

    Button button1;
    Button button2;
    
    
    this(gtk.Application.Application application){
        
        super(application);

        headerBar = new HeaderBar();
        with (headerBar) {
            setTitle("Welcome");
            setShowCloseButton(true);
            setHasSubtitle(false);
            
            add(new Image("go-home", IconSize.DIALOG));
        }

        setTitlebar(headerBar);

        setDefaultSize(400, 200);
        setResizable(false);

        vbox1 = new Fixed();

        button1 = new Button("TreeView Example");
        button2 = new Button("ListBox Example");

        button2.addOnReleased((Button b){
            auto pencere = new Ornek2();
            pencere.show();
        });

        button1.addOnReleased(toDelegate(&button1OnClicked));
        
        this.addOnDelete(delegate bool(Event e, Widget w) {
            exit(0);
            return true;
        });
        
        
        import gtk.c.functions;
        gtk_widget_set_size_request(cast(GtkWidget*)button1.getButtonStruct, 210, 34);
        gtk_widget_set_size_request(cast(GtkWidget*)button2.getButtonStruct, 210, 34);

        vbox1.put(button1, 93, 36);
        vbox1.put(button2, 93, 87);
        
        add(vbox1);
        

        showAll();
    }

    void button1OnClicked(Button b){
        auto win = new Ornek1();
        win.show();
    }
}