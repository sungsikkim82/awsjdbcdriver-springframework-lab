package org.support.engineering.awsjdbcdriverspringframeworklab.config;

import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Connection;

@Configuration
public class DataSourceConfig implements SmartInitializingSingleton {

    private static final Logger log = LoggerFactory.getLogger(DataSourceConfig.class);
    private HikariDataSource readerDs;

    @Primary
    @Bean
    @ConfigurationProperties("datasource.writer")
    public HikariDataSource writerDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }

    @Bean
    @ConfigurationProperties("datasource.reader")
    public HikariDataSource readerDataSource() {
        readerDs = DataSourceBuilder.create().type(HikariDataSource.class).build();
        return readerDs;
    }

    @Primary
    @Bean
    public JdbcTemplate writerJdbcTemplate() {
        return new JdbcTemplate(writerDataSource());
    }

    @Bean
    public JdbcTemplate readerJdbcTemplate() {
        return new JdbcTemplate(readerDataSource());
    }

    @Override
    public void afterSingletonsInstantiated() {
        try (Connection conn = readerDs.getConnection()) {
            log.info("reader-pool eagerly initialized");
        } catch (Exception e) {
            log.error("Failed to eagerly initialize reader-pool", e);
        }
    }
}
