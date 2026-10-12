WITH
common_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim dcs ON cs.cs_sold_date_sk = dcs.d_date_sk
    WHERE dcs.d_year BETWEEN 2000 AND 2002
    GROUP BY cs.cs_item_sk
    INTERSECT
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim dss ON ss.ss_sold_date_sk = dss.d_date_sk
    WHERE dss.d_year BETWEEN 2000 AND 2002
    GROUP BY ss.ss_item_sk
),
combined_sales AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        'CATALOG' AS channel,
        cs.cs_order_number AS order_number,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN concat('Cat_Discount_', CAST(cs.cs_ext_discount_amt AS varchar)) ELSE NULL END AS discount_tag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND (d.d_month_seq % 2 = 0 OR d.d_month_seq % 3 = 0)
      AND cs.cs_item_sk IN (SELECT item_sk FROM common_items)

    UNION ALL

    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        'STORE' AS channel,
        ss.ss_ticket_number AS order_number,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_item_sk AS item_sk,
        NULL AS call_center_sk,
        CASE WHEN ss.ss_ext_discount_amt > 0 THEN concat('Store_Discount_', CAST(ss.ss_ext_discount_amt AS varchar)) ELSE NULL END AS discount_tag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND (d.d_month_seq % 2 = 0 OR d.d_month_seq % 3 = 0)
      AND ss.ss_item_sk IN (SELECT item_sk FROM common_items)

    UNION ALL

    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        'WEB' AS channel,
        ws.ws_order_number AS order_number,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_item_sk AS item_sk,
        NULL AS call_center_sk,
        CASE WHEN ws.ws_ext_discount_amt > 0 THEN concat('Web_Discount_', CAST(ws.ws_ext_discount_amt AS varchar)) ELSE NULL END AS discount_tag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND (d.d_month_seq % 2 = 0 OR d.d_month_seq % 3 = 0)
      AND ws.ws_item_sk IN (SELECT item_sk FROM common_items)
),
month_channel_raw AS (
    SELECT
        d_year,
        d_month_seq,
        channel,
        COUNT(DISTINCT order_number) AS orders,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(CASE WHEN discount_tag IS NOT NULL THEN 1 ELSE 0 END) AS discount_count
    FROM combined_sales
    GROUP BY d_year, d_month_seq, channel
),
month_channel_agg AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
    FROM month_channel_raw r
),
channel_month_discount AS (
    SELECT
        mcr.d_year,
        mcr.d_month_seq,
        mcr.channel,
        (SELECT AVG(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt / cs.cs_ext_sales_price END)
         FROM catalog_sales cs
         JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
         WHERE d.d_year = mcr.d_year
           AND d.d_month_seq = mcr.d_month_seq) AS avg_catalog_discount_ratio,
        (SELECT AVG(CASE WHEN ss.ss_ext_discount_amt > 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_sales_price END)
         FROM store_sales ss
         JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
         WHERE d.d_year = mcr.d_year
           AND d.d_month_seq = mcr.d_month_seq) AS avg_store_discount_ratio,
        (SELECT AVG(CASE WHEN ws.ws_ext_discount_amt > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_sales_price END)
         FROM web_sales ws
         JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
         WHERE d.d_year = mcr.d_year
           AND d.d_month_seq = mcr.d_month_seq) AS avg_web_discount_ratio
    FROM month_channel_raw mcr
),
catalog_cc_by_month AS (
    SELECT
        d_year,
        d_month_seq,
        MIN(call_center_sk) AS call_center_sk
    FROM combined_sales
    WHERE channel = 'CATALOG' AND call_center_sk IS NOT NULL
    GROUP BY d_year, d_month_seq
),
call_center_info AS (
    SELECT
        ccm.d_year,
        ccm.d_month_seq,
        cc.cc_name AS call_center_name,
        cc.cc_state AS call_center_state
    FROM catalog_cc_by_month ccm
    LEFT JOIN call_center cc ON ccm.call_center_sk = cc.cc_call_center_sk
),
item_returns AS (
    SELECT
        item_sk,
        SUM(return_quantity) AS total_return_quantity,
        SUM(total_loss) AS total_ret_loss
    FROM (
        SELECT cr_item_sk AS item_sk,
               cr_return_quantity AS return_quantity,
               cr_net_loss AS total_loss
        FROM catalog_returns
        UNION ALL
        SELECT sr_item_sk AS item_sk,
               sr_return_quantity AS return_quantity,
               sr_net_loss AS total_loss
        FROM store_returns
        UNION ALL
        SELECT wr_item_sk AS item_sk,
               wr_return_quantity AS return_quantity,
               wr_net_loss AS total_loss
        FROM web_returns
    ) all_ret
    GROUP BY item_sk
),
top_item_returns AS (
    SELECT
        t.d_year,
        t.d_month_seq,
        t.channel,
        ir.total_ret_loss AS top_item_ret_loss
    FROM (
        SELECT
            d_year,
            d_month_seq,
            channel,
            item_sk,
            net_profit,
            ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit DESC) AS rn
        FROM combined_sales
    ) t
    JOIN item_returns ir ON t.item_sk = ir.item_sk
    WHERE t.rn = 1
)
SELECT
    mca.d_year,
    mca.d_month_seq,
    mca.channel,
    mca.orders,
    mca.total_net_paid,
    mca.total_net_profit,
    mca.discount_count,
    mca.profit_rank,
    CONCAT('Rank_', CAST(mca.profit_rank AS varchar), '_', mca.channel) AS rank_desc,
    COALESCE(cc.call_center_name, 'N/A') AS call_center_name,
    COALESCE(cc.call_center_state, 'N/A') AS call_center_state,
    CASE
        WHEN mca.channel = 'CATALOG' THEN cmd.avg_catalog_discount_ratio
        WHEN mca.channel = 'STORE' THEN cmd.avg_store_discount_ratio
        WHEN mca.channel = 'WEB' THEN cmd.avg_web_discount_ratio
    END AS avg_discount_ratio,
    COALESCE(tir.top_item_ret_loss, 0) AS top_item_ret_loss
FROM month_channel_agg mca
LEFT JOIN channel_month_discount cmd
    ON mca.d_year = cmd.d_year AND mca.d_month_seq = cmd.d_month_seq AND mca.channel = cmd.channel
LEFT JOIN call_center_info cc
    ON mca.d_year = cc.d_year AND mca.d_month_seq = cc.d_month_seq
LEFT JOIN top_item_returns tir
    ON mca.d_year = tir.d_year AND mca.d_month_seq = tir.d_month_seq AND mca.channel = tir.channel
WHERE mca.profit_rank <= 3
ORDER BY mca.d_year, mca.d_month_seq, mca.profit_rank
