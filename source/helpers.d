module helpers;

import std.experimental.logger: trace;

import gtk.ListStore, gtk.TreeView, gtk.TreeModelIF, gtk.TreeSelection, gtk.CellRendererText,
    gtk.CellRendererToggle, gtk.TreePath, gtk.TreeIter, gtk.TreeViewColumn;


template getCType(T)
{
    static if ( is(T == class) )
        alias getCType = typeof(T.tupleof[0]);
    else
        alias getCType = void*;
}

T getMyDObject(T, TC = getCType!T)(void* data){
    import gobject.ObjectG;
    
    T ret = ObjectG.getDObject!(T)(cast(TC)data);

    return ret;
}

struct TreeIterRange {

private:
    TreeModelIF model;
    TreeIter iter;
    bool _empty;

public:
    this(TreeModelIF model) {
        this.model = model;
        _empty = !model.getIterFirst(iter);
    }

    this(TreeModelIF model, TreeIter parent) {
        this.model = model;
        _empty = !model.iterChildren(iter, parent);
        if (_empty) trace("TreeIter has no children");
    }

    @property bool empty() {
        return _empty;
    }

    @property auto front() {
        return iter;
    }

    void popFront() {
        _empty = !model.iterNext(iter);
    }

    /**
     * Based on the example here https://www.sociomantic.com/blog/2010/06/opapply-recipe/#.Vm8mW7grKEI
     */
    int opApply(int delegate(ref TreeIter iter) dg) {
        int result = 0;
        //bool hasNext = model.getIterFirst(iter);
        bool hasNext = !_empty;
        while (hasNext) {
            result = dg(iter);
            if (result) {
                break;
            }
            hasNext = model.iterNext(iter);
        }
        return result;
    }
}
/+
import gtk.TreeModel;

void foreach_model(ListStore listStore, int delegate(ref TreeModel, ref TreePath, ref TreeIter) cb)
{
    ListStoreForeachCallback cbWrap = (model, path, iter) {
        return cb(model, path, iter);
    };
    listStore.foreac(&listStoreForeachCallback, cast(void*)&cbWrap);
}

private alias ListStoreForeachCallback = int delegate(TreeModel, TreePath, TreeIter);

private extern (C) int listStoreForeachCallback(GtkTreeModel* model, GtkTreePath* path,
        GtkTreeIter* iter, void* data)
{
    auto fn = *(cast(ListStoreForeachCallback*) data);
    return fn(new TreeModel(model), new TreePath(path), new TreeIter(iter));
}
+/