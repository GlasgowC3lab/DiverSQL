WITH catalog_agg AS (
    SELECT
        r.r_reason_desc,
        r.r_reason_id,
        SUM(cr.cr_net_loss) AS catalog_loss,
        COUNT(*) AS catalog_cnt,
        CONCAT('Catalog-', r.r_reason_id) AS reason_key
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
      AND i.i_color LIKE 'Red%'
    GROUP BY r.r_reason_desc, r.r_reason_id
),
web_agg AS (
    SELECT
        r.r_reason_desc,
        r.r_reason_id,
        SUM(wr.wr_net_loss) AS web_loss,
        COUNT(*) AS web_cnt,
        CONCAT('Web-', r.r_reason_id) AS reason_key
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
      AND i.i_color LIKE 'Red%'
    GROUP BY r.r_reason_desc, r.r_reason_id
)
SELECT
    u.reason_desc,
    SUM(u.total_loss) AS total_loss,
    SUM(u.total_cnt) AS total_cnt
FROM (
    SELECT
        r_reason_desc AS reason_desc,
        catalog_loss AS total_loss,
        catalog_cnt AS total_cnt
    FROM catalog_agg
    UNION
    SELECT
        r_reason_desc AS reason_desc,
        web_loss AS total_loss,
        web_cnt AS total_cnt
    FROM web_agg
) u
GROUP BY u.reason_desc
HAVING SUM(u.total_loss) > (
    SELECT AVG(reason_loss)
    FROM (
        SELECT SUM(cr.cr_net_loss) AS reason_loss
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        GROUP BY r.r_reason_sk
    ) avg_sub
)
ORDER BY total_loss DESC
LIMIT 100
