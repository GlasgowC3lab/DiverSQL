WITH item_agg AS (
    SELECT
        i.i_item_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        SUM(cs.cs_net_profit) AS sum_cs_profit,
        SUM(ss.ss_net_profit) AS sum_ss_profit,
        SUM(wr.wr_net_loss) AS sum_wr_loss,
        CASE
            WHEN SUM(cs.cs_net_profit) > 5000 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        cs.cs_list_price > 100
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
    GROUP BY
        i.i_item_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound
)
SELECT
    profit_category,
    COUNT(*) AS item_cnt,
    SUM(sum_cs_profit) AS total_cs_profit,
    SUM(sum_ss_profit) AS total_ss_profit,
    SUM(sum_wr_loss) AS total_wr_loss,
    AVG(sum_cs_profit) AS avg_cs_profit_per_item,
    ROW_NUMBER() OVER (ORDER BY SUM(sum_cs_profit) DESC) AS rn
FROM item_agg
GROUP BY profit_category
ORDER BY total_cs_profit DESC
LIMIT 100
