package org.support.engineering.awsjdbcdriverspringframeworklab.controller;

import org.springframework.web.bind.annotation.*;
import org.support.engineering.awsjdbcdriverspringframeworklab.service.QueryService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/query")
public class QueryController {

    private final QueryService queryService;

    public QueryController(QueryService queryService) {
        this.queryService = queryService;
    }

    @PostMapping("/read")
    public List<Map<String, Object>> read(@RequestBody Map<String, String> request) {
        return queryService.executeReadQuery(request.get("sql"));
    }

    @PostMapping("/write")
    public List<Map<String, Object>> write(@RequestBody Map<String, String> request) {
        return queryService.executeWriteQuery(request.get("sql"));
    }
}
