-- define lmake if not already defined
	if not DEF_LMAKE then
		DEF_LMAKE = true
	
		package.path = package.path..";;"..debug.getinfo(1, "S").source:sub(2):match("(.*/)") .. "?.lua"
		require("src.external")

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
		
		os.exit()
	end
