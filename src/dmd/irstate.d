/**
 * Used to help transform statement AST into flow graph.
 * Compiler implementation of the
 * $(LINK2 http://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (C) 1999-2020 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 http://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/src/dmd/irstate.d, _irstate.d)
 * Documentation: https://dlang.org/phobos/dmd_irstate.html
 * Coverage:    https://codecov.io/gh/dlang/dmd/src/master/src/dmd/irstate.d
 */

module dmd.irstate;

import dmd.identifier;
import dmd.statement;

import dmd.backend.cc; // for `block`

/************************************************
 * Used to traverse the statement AST to transform it into
 * a flow graph.
 * Keeps track of things like "where does the `break` go".
 */
struct StmtState
{
    StmtState* prev;
    Statement statement;

    Identifier ident;
    block* breakBlock;
    block* contBlock;
    block* switchBlock;
    block* defaultBlock;
    block* finallyBlock;

    this(StmtState* prev, Statement statement)
    {
        this.prev = prev;
        this.statement = statement;
    }

    block* getBreakBlock(Identifier ident)
    {
        StmtState* bc;
        if (ident)
        {
            Statement related = null;
            block* ret = null;
            for (bc = &this; bc; bc = bc.prev)
            {
                // The label for a breakBlock may actually be some levels up (e.g.
                // on a try/finally wrapping a loop). We'll see if this breakBlock
                // is the one to return once we reach that outer statement (which
                // in many cases will be this same statement).
                if (bc.breakBlock)
                {
                    related = bc.statement.getRelatedLabeled();
                    ret = bc.breakBlock;
                }
                if (bc.statement == related && bc.prev.ident == ident)
                    return ret;
            }
        }
        else
        {
            for (bc = &this; bc; bc = bc.prev)
            {
                if (bc.breakBlock)
                    return bc.breakBlock;
            }
        }
        return null;
    }

    block* getContBlock(Identifier ident)
    {
        StmtState* bc;
        if (ident)
        {
            block* ret = null;
            for (bc = &this; bc; bc = bc.prev)
            {
                // The label for a contBlock may actually be some levels up (e.g.
                // on a try/finally wrapping a loop). We'll see if this contBlock
                // is the one to return once we reach that outer statement (which
                // in many cases will be this same statement).
                if (bc.contBlock)
                {
                    ret = bc.contBlock;
                }
                if (bc.prev && bc.prev.ident == ident)
                    return ret;
            }
        }
        else
        {
            for (bc = &this; bc; bc = bc.prev)
            {
                if (bc.contBlock)
                    return bc.contBlock;
            }
        }
        return null;
    }

    block* getSwitchBlock()
    {
        StmtState* bc;
        for (bc = &this; bc; bc = bc.prev)
        {
            if (bc.switchBlock)
                return bc.switchBlock;
        }
        return null;
    }

    block* getDefaultBlock()
    {
        StmtState* bc;
        for (bc = &this; bc; bc = bc.prev)
        {
            if (bc.defaultBlock)
                return bc.defaultBlock;
        }
        return null;
    }

    block* getFinallyBlock()
    {
        StmtState* bc;
        for (bc = &this; bc; bc = bc.prev)
        {
            if (bc.finallyBlock)
                return bc.finallyBlock;
        }
        return null;
    }
}
