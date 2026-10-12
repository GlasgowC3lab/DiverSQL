WITH
    -- Pre‑aggregate store returns with required joins
    store_pre AS (
        SELECT
            sr.sr_addr_sk,
            sr.sr_return_amt,
            sr.sr_net_loss,
            d.d_year,
            t.t_hour,
            r.r_reason_desc
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    ),
    store_agg AS (
        SELECT
            sr_addr_sk,
            SUM(sr_return_amt)          AS total_store_return,
            AVG(sr_net_loss)            AS avg_store_net_loss,
            COUNT(*)                    AS cnt_store_returns,
            MIN(d_year)                 AS min_year_store,
            MAX(d_year)                 AS max_year_store
        FROM store_pre
        WHERE d_year BETWEEN 2000 AND 2002
          AND t_hour = 12
          AND r_reason_desc LIKE '%missing%'
        GROUP BY sr_addr_sk
    ),
    -- Pre‑aggregate web returns with required joins
    web_pre AS (
        SELECT
            wr.wr_returning_addr_sk,
            wr.wr_return_amt,
            wr.wr_net_loss,
            d.d_year,
            t.t_hour,
            r.r_reason_desc,
            wp.wp_type
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    ),
    web_agg AS (
        SELECT
            wr_returning_addr_sk,
            SUM(wr_return_amt)          AS total_web_return,
            AVG(wr_net_loss)            AS avg_web_net_loss,
            COUNT(*)                    AS cnt_web_returns,
            MIN(d_year)                 AS min_year_web,
            MAX(d_year)                 AS max_year_web
        FROM web_pre
        WHERE d_year = 2001
          AND t_hour = 12
          AND r_reason_desc LIKE '%working%'
        GROUP BY wr_returning_addr_sk
    ),
    -- Addresses that appear in both aggregates
    common_addrs AS (
        SELECT sr_addr_sk AS address_sk FROM store_agg
        INTERSECT
        SELECT wr_returning_addr_sk FROM web_agg
    ),
    -- Anti‑semi‑join on web_site (exclude sites in CA)
    filtered_web_site AS (
        SELECT ws.*
        FROM web_site ws
        WHERE ws.web_site_sk NOT IN (
            SELECT ws2.web_site_sk FROM web_site ws2 WHERE ws2.web_state = 'CA'
        )
    )
SELECT
    final.ca_address_id,
    final.ca_city,
    final.ca_state,
    final.total_store_return,
    final.avg_store_net_loss,
    final.total_web_return,
    final.avg_web_net_loss,
    final.higher_source,
    metric,
    amount
FROM (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        sa.total_store_return,
        sa.avg_store_net_loss,
        wa.total_web_return,
        wa.avg_web_net_loss,
        CASE
            WHEN sa.total_store_return > wa.total_web_return THEN 'Store Higher'
            ELSE 'Web Higher'
        END AS higher_source,
        map(
            array['store','web'],
            array[sa.total_store_return, wa.total_web_return]
        ) AS source_map
    FROM common_addrs ca_addr
    JOIN store_agg sa ON ca_addr.address_sk = sa.sr_addr_sk
    JOIN web_agg wa   ON ca_addr.address_sk = wa.wr_returning_addr_sk
    JOIN customer_address ca ON ca_addr.address_sk = ca.ca_address_sk
    JOIN filtered_web_site fws ON fws.web_open_date_sk = (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001 LIMIT 1
    )
) final
CROSS JOIN UNNEST(final.source_map) AS t(metric, amount)
ORDER BY
    amount DESC,
    final.ca_state ASC
LIMIT 100
