		
		-- io operations
			-- pritntt()
				function printt(tbl, lvl)
					lvl = lvl or 0
					assert(type(tbl) == "table", string.format("you must pass a table to prtintt ( passed %s )", type(tbl)))
					io.write("{\n")
					for k,v in pairs(tbl) do
						for i=0,lvl do
							io.write("\t")	
						end

						if type(v) == "table" then
							io.write(k .. " = ")
							printt(v, lvl+1)
						elseif tostring(v) then
							printf("%s = %s\n", tostring(k), tostring(v))
						end
					end
					for i=0,lvl-1 do
						io.write("\t")	
					end
					io.write("}\n")
				end
			
			-- printf
				function printf(format, ...)
					assertf(format, "you must pass a format and any format subsitutions to printf") 
					if type(format) == "string" then
						io.write(#{...} > 0 and string.format(format .. "\n", ...) or ( format and format .. '\n' or ""))
						io.flush()
					else
						return printf(tostring(format) or nil, ...)
					end
				end

		-- string operations
			-- escapes all lua magic characters (makeing it ready to use in a match)
				function string.escape(str)
					local magic_chars = { '%%', '%(', '%)', '%.', '%+', '%–', '%*', '%?', '%[', '%^', '%$'}
					for k,char in pairs(magic_chars) do
						str = str:gsub(char, char:gsub("%%", "%%%%"))		
					end
					return str
				end

			-- string.split

		-- file operations
			-- io.openf()
				function io.openf(format, ...)
					local args = {...}
					local mode = table.remove(args)
					return io.open(string.format(format, table.unpack(args)), mode)
				end

			-- io.popenf()
				function io.popenf(format, ...)
					return io.popen(string.format(format, ...))
				end

			-- io.writef()
				function io.writef(file, format, ...)
					io.output(file)
					io.write(string.format(format, ...))
					io.output(io.stdout);
				end

			-- get size of file	
				function io.size(file)
					local position = file:seek()
					local size = file:seek("end")
					file:seek("set", position)
					return size
				end

			-- get chars to end of file end
				function io.toend(file)
					return io.size(file) - file:seek()
				end

			-- get pwd
				function io.pwd()
					return os.getenv("PWD"):match(".*/.-/(.*)")
				end

			-- get file tree
				function io.tree(dir)
					-- e.g. (dirs = { dir1 = { subdir1 = {}, subdir2 = {} }})  
					assert(dir, "you must pass a dir to io.tree")
					local dirs = {}
					for subdir in io.popen("ls -d "..dir.."/*/ 2> /dev/null"):lines() do
						dirs[subdir:sub(#dir+2, -2)] = io.tree(subdir:sub(1, -2))
					end
					return dirs
				end

		-- task_system
			local tasks = {}
			local task_complete = false
			
			-- task_indent
				function task_indent(char)
					local indent = ''
					for _,v in ipairs(tasks) do indent = indent .. ( char or '\t') end
					return indent
				end
			
			-- task_add
				function task(task)
					io.write( ((not task_complete and #tasks > 0)  and "\n" or "") .. task_indent() .. task .. ": ")
					table.insert(tasks, task)
					task_complete = false
				end

			-- task_done 
				function task_done(task)
					io.write(( task and task..": "or "" )..(not task_complete and "done\n" or ""))
					table.remove(tasks)
					task_complete = true 
				end

-- external function defintions	
			function assertf(expression, format, ...)
				if not expression then
					printf(format, ...)
					os.exit(1)
				end
			end

		-- cmd	 (run command with live output)
			function cmd(cmd_format, ...)
				assert(cmd_format and cmd_format ~= "", "you must pass a command to cmd(cmd_format, ...)")
				local out, err = "", ""
					
				local stdout, stderr, cmd_done = os.tmpname(), os.tmpname(), os.tmpname()
				io.popen( "{ " .. string.format(string.format(cmd_format, ...) .. "; }>> %s 2>> %s; echo > %s", stdout, stderr, cmd_done ))
				stdout, stderr, cmd_done = io.open(stdout, "r"), io.open(stderr, "r"), io.open(cmd_done, "r")
				
				while io.toend(cmd_done) == 0 do
					io.write( stdout:read(io.toend(stdout)) or "" )
					io.write( stderr:read(io.toend(stderr)) or "" )
				end
			end

