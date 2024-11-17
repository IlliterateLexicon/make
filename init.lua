-- define lmake if not already defined
	if not DEF_LMAKE then
		DEF_LMAKE = true
		
		-- external function defintions	
			-- make assert less ugly
				_assert = assert
				function assert(expression, error)
					if not expression then
						print(error)
						os.exit(1)
					end
				end

			-- file operations
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
			
			-- task_system
				local tasks = {}
				local task_complete = false
				
				-- task_add
					function task(task)
						local indent = ""
						for i,v in ipairs(tasks) do indent = indent .. "\t" end
						io.write( ((not task_complete and #tasks > 0)  and "\n" or "") .. indent .. task .. ": ")
						table.insert(tasks, task)
						task_complete = false
					end

				-- task_done 
					function task_done()
						io.write(not task_complete and "done\n" or "")
						table.remove(tasks)
						task_complete = true 
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
	
		-- parse makefile		
			-- get path of the file that required this file 
				local makefile_path = debug.getinfo(3, "S").source:sub(2)

			-- require that file
				local path_cache = package.path
				package.path = package.path .. ";;" .. os.getenv("PWD") .. "/?"
				require(makefile_path)
				package.path = path_cache

			-- parse targets from global table file
				local make_targets = {}
				local make_targets_num = 0
				for k,v in pairs(_G) do
					if type(v) == "function" and k:sub(1, 5) == "make_" then
						make_targets_num = make_targets_num + 1
						make_targets[k:sub(6)] = v
					end
				end		
				assert(make_targets_num>0, "\n\t\tno targets defined. \n\t\tdefine a target by prefixing a function with 'make_'\n\t\te.g make_target()")

			-- command line options
				make_args = {}
				
				-- print commands	
				function print_commands()
					print("testing")			
				end

				make_args["-pc"]							= print_commands
				make_args["--print-commands"] = print_commands
			
			-- parse cmd line args
				if #arg == 0 then 
					-- run refault target
					assert(make_targets["default"], "no target was specified; no default target defined")
					make_targets["default"]()	
				else
					for i,arg in ipairs(arg) do
						if make_args[arg] then make_args[arg]() end
						assert(make_targets[arg], "'" .. arg .. "' is not a valid target key.")
						make_targets[arg]()
					end
				end
	end
