local M = {}

local last_results = {}

M.filter_request = function(method, handler, filter, callback_on_discard)
    local params = vim.lsp.util.make_position_params()

    handler = handler or vim.lsp.handlers[method]
    if not handler then
        print("No default handler for method", method)
        return
    end


    vim.lsp.buf_request(0, method, params, function(err, results, ctx)
        if not filter or err or not results or #results <= 1 then
            handler(err, results, ctx)
            return
        end

        local filtered_results = {}
        local discarded_results = {}
        for _, result in ipairs(results) do
            table.insert(filter(result) and filtered_results or discarded_results, result)
        end

        last_results = {
            handler = handler,
            full_results = results,
            discarded_results = discarded_results,
            ctx = ctx,
        } 

        if #filtered_results > 0 then
            handler(err, filtered_results, ctx)

            if callback_on_discard and #discarded_results > 0 then 
                callback_on_discard(discarded_results)
            end

        -- If there aren't any results left after filtering, show the full results
        else
            handler(err, results, ctx)
        end
    end)
end

M.full_results = function()
    local l = last_results
    l.handler(nil, l.full_results, l.ctx)
end

M.discarded_results = function()
    local l = last_results
    l.handler(nil, l.discarded_results, l.ctx)
end

M.references = function(...) M.filter_request("textDocument/references", ...) end
M.definition = function(...) M.filter_request("textDocument/definition", ...) end
M.implementation = function(...) M.filter_request("textDocument/implementation", ...) end

--TODO Actually make this work
M.setup = function(config) 
    M.filetypes = config.filetypes or nil 
end

return M
