WITH cat_agg AS (
    SELECT
        cd.cd_demo_sk,
        w.w_city,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_ext_discount_amt) AS cat_total_discount,
        COUNT(*) AS cat_sales_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_tax > 0
    GROUP BY cd.cd_demo_sk, w.w_city
),
store_agg AS (
    SELECT
        cd.cd_demo_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_total_discount,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_ext_tax > 0
    GROUP BY cd.cd_demo_sk
),
return_agg AS (
    SELECT
        cd.cd_demo_sk,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
    GROUP BY cd.cd_demo_sk, r.r_reason_desc
)
SELECT *
FROM (
    SELECT
        ca.w_city,
        cd.cd_gender,
        cd.cd_education_status,
        ca.cat_net_profit,
        sa.store_net_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        ca.cat_sales_cnt,
        sa.store_sales_cnt,
        COALESCE(ra.return_cnt, 0) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY ca.w_city ORDER BY ca.cat_net_profit DESC) AS city_rank
    FROM cat_agg ca
    JOIN store_agg sa ON ca.cd_demo_sk = sa.cd_demo_sk
    LEFT JOIN return_agg ra ON ca.cd_demo_sk = ra.cd_demo_sk AND ra.r_reason_desc = 'Damaged'
    JOIN customer_demographics cd ON ca.cd_demo_sk = cd.cd_demo_sk
    WHERE ca.cat_net_profit > 0
) t
WHERE t.city_rank <= 5
ORDER BY t.cat_net_profit DESC
LIMIT 100
