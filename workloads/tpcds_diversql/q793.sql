WITH
    -- Full outer join between date_dim and store_returns (first two tables)
    date_store AS (
        SELECT
            d.d_date_sk,
            d.d_year,
            d.d_quarter_name,
            sr.sr_store_sk,
            sr.sr_item_sk,
            sr.sr_return_amt_inc_tax,
            sr.sr_net_loss,
            sr.sr_return_quantity
        FROM date_dim d
        FULL OUTER JOIN store_returns sr
            ON d.d_date_sk = sr.sr_returned_date_sk
        WHERE d.d_year = 2001                     -- filter 1
          AND d.d_quarter_name = 'Q1'             -- filter 2
    ),
    -- Inner join the result with web_site (third table)
    date_store_site AS (
        SELECT
            ds.*,
            ws.web_site_id,
            ws.web_company_id,
            ws.web_state,
            ws.web_gmt_offset
        FROM date_store ds
        JOIN web_site ws
            ON ws.web_open_date_sk = ds.d_date_sk
        WHERE ws.web_company_id IN (1, 3, 5)      -- filter 3
          AND ws.web_state = 'CA'                -- filter 4
    ),
    -- Small computed set for a cross join
    thresholds AS (
        SELECT value AS min_loss FROM (VALUES (100.00), (500.00), (1000.00)) AS t(value)
    ),
    -- Cross join a tiny slice of the previous result with the thresholds
    cross_data AS (
        SELECT
            dss.*, 
            t.min_loss
        FROM (
            SELECT *
            FROM date_store_site
            ORDER BY d_date_sk DESC
            LIMIT 5
        ) dss
        CROSS JOIN thresholds t
    ),
    -- Item sets for the EXCEPT operation
    high_loss_items AS (
        SELECT DISTINCT sr_item_sk
        FROM store_returns
        WHERE sr_net_loss > 500
    ),
    low_loss_items AS (
        SELECT DISTINCT sr_item_sk
        FROM store_returns
        WHERE sr_net_loss < 50
    ),
    item_excluded AS (
        SELECT sr_item_sk
        FROM high_loss_items
        EXCEPT
        SELECT sr_item_sk
        FROM low_loss_items
    )
SELECT
    cd.web_site_id,
    cd.web_company_id,
    cd.d_quarter_name,
    cd.min_loss,
    COUNT(DISTINCT cd.sr_store_sk)                      AS store_count,
    SUM(cd.sr_net_loss)                                 AS total_net_loss,
    AVG(cd.sr_return_amt_inc_tax)                       AS avg_return_amt_inc_tax,
    MIN(cd.sr_net_loss)                                 AS min_net_loss,
    MAX(cd.sr_net_loss)                                 AS max_net_loss,
    LAG(SUM(cd.sr_net_loss)) OVER (PARTITION BY cd.web_company_id ORDER BY cd.min_loss) AS lag_total_net_loss,
    SUM(SUM(cd.sr_net_loss)) OVER (PARTITION BY cd.web_company_id ORDER BY cd.min_loss ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_loss
FROM cross_data cd
JOIN item_excluded ie
    ON cd.sr_item_sk = ie.sr_item_sk
GROUP BY
    cd.web_site_id,
    cd.web_company_id,
    cd.d_quarter_name,
    cd.min_loss
HAVING SUM(cd.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
