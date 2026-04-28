package org.support.engineering.awsjdbcdriverspringframeworklab.service;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class QueryService {

    private final JdbcTemplate writerJdbcTemplate;
    private final JdbcTemplate readerJdbcTemplate;

    public QueryService(@Qualifier("writerJdbcTemplate") JdbcTemplate writerJdbcTemplate,
                        @Qualifier("readerJdbcTemplate") JdbcTemplate readerJdbcTemplate) {
        this.writerJdbcTemplate = writerJdbcTemplate;
        this.readerJdbcTemplate = readerJdbcTemplate;
    }

    public List<Map<String, Object>> executeReadQuery(String sql) {
        return readerJdbcTemplate.queryForList(sql);
    }

    public List<Map<String, Object>> executeWriteQuery(String sql) {
        writerJdbcTemplate.execute(sql);
        return List.of(Map.of("result", "executed"));
    }
}
