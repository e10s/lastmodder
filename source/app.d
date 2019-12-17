void main(string[] args)
{
    bool dryRun;
    import std.getopt : GetOptException;

    try
    {
        import std.getopt : getopt;
        import std.range.primitives : popFront, empty;

        auto opts = getopt(args, "dry|d", "Perform dry run.", &dryRun);
        args.popFront();

        if (args.empty || opts.helpWanted)
        {
            import std.getopt : defaultGetoptPrinter;

            defaultGetoptPrinter("** LASTMODDER **\n\n<OPTIONS>\n", opts.options);
            return;
        }
    }
    catch (GetOptException e)
    {
        import std.stdio : stderr, writefln;

        stderr.writefln!"Error: %s"(e.msg);
        return;
    }

    foreach (arg; args)
    {
        import std.file : exists, isDir;

        if (!arg.exists || !arg.isDir)
        {
            import std.stdio : stderr, writefln;

            stderr.writefln!"Bad directory: %s"(arg);
            continue;
        }

        import std.stdio : writefln;
        import std.path : asAbsolutePath, asNormalizedPath;
        import std.algorithm.iteration : filter;

        writefln!`Entering "%s"...`(arg.asAbsolutePath.asNormalizedPath);
        import std.file : dirEntries, SpanMode;

        auto dirs = arg.dirEntries(SpanMode.shallow).filter!(e => e.isDir);
        foreach (dir; dirs)
        {
            import std.path : baseName;
            import std.file : DirEntry, FileException;

            writefln!` "%s"`(dir.baseName);

            DirEntry[] files;
            try
            {
                import std.array : array;

                files = dir.dirEntries(SpanMode.shallow).filter!(e => e.isFile).array;
            }
            catch (FileException e)
            {
                import std.stdio : stderr;

                stderr.writefln!"  Error: %s"(e.msg);
            }
            import std.range.primitives : empty;

            if (files.empty)
            {
                import std.stdio : writeln;

                writeln("  Skip");
            }
            else
            {
                import std.datetime : SysTime;
                import std.algorithm.searching : maxElement;

                immutable dirLastAcc = dir.timeLastAccessed;
                immutable dirLastMod = dir.timeLastModified;
                immutable latestLastModFile = files.maxElement!(e => e.timeLastModified);

                writefln!"  Change: %s -> %s, as %s"(dirLastMod,
                        latestLastModFile.timeLastModified, latestLastModFile.baseName);
                if (!dryRun)
                {
                    try
                    {
                        import std.file : setTimes;

                        setTimes(dir, dirLastAcc, latestLastModFile.timeLastModified);
                    }
                    catch (FileException e)
                    {
                        import std.stdio : stderr;

                        stderr.writefln!"  Error: %s"(e.msg);
                    }
                }
            }
        }
    }
}
