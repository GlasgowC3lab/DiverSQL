WITH
store_sales_agg AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_ext_tax) AS total_tax
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_state, d.d_year, d.d_moy
),
catalog_sales_agg AS (
    SELECT
        cc.cc_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_state, d.d_year, d.d_moy
),
web_sales_agg AS (
    SELECT
        ws_site.web_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_net_profit) AS profit_amount,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws_site.web_state, d.d_year, d.d_moy
),
store_returns_agg AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_net_loss) AS return_loss,
        SUM(sr.sr_return_quantity) AS return_quantity
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_state, d.d_year, d.d_moy
),
catalog_returns_agg AS (
    SELECT
        cc.cc_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_net_loss) AS return_loss,
        SUM(cr.cr_return_quantity) AS return_quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cc.cc_state, d.d_year, d.d_moy
),
web_returns_agg AS (
    SELECT
        ws_site.web_state AS state,
        d_ret.d_year AS year,
        d_ret.d_moy AS month,
        SUM(wr.wr_return_amt) AS return_amount,
        SUM(wr.wr_net_loss) AS return_loss,
        SUM(wr.wr_return_quantity) AS return_quantity
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    GROUP BY ws_site.web_state, d_ret.d_year, d_ret.d_moy
),
sales_union AS (
    SELECT 'STORE' AS channel, state, year, month,
        sales_amount, profit_amount, total_quantity, total_discount, total_tax
    FROM store_sales_agg
    UNION ALL
    SELECT 'CATALOG' AS channel, state, year, month,
        sales_amount, profit_amount, total_quantity, total_discount, total_tax
    FROM catalog_sales_agg
    UNION ALL
    SELECT 'WEB' AS channel, state, year, month,
        sales_amount, profit_amount, total_quantity, total_discount, total_tax
    FROM web_sales_agg
),
returns_union AS (
    SELECT 'STORE' AS channel, state, year, month,
        return_amount, return_loss, return_quantity
    FROM store_returns_agg
    UNION ALL
    SELECT 'CATALOG' AS channel, state, year, month,
        return_amount, return_loss, return_quantity
    FROM catalog_returns_agg
    UNION ALL
    SELECT 'WEB' AS channel, state, year, month,
        return_amount, return_loss, return_quantity
    FROM web_returns_agg
),
item_sales AS (
    SELECT
        'STORE' AS channel,
        s.s_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        i.i_item_id AS item_id,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_state, d.d_year, d.d_moy, i.i_item_id
    UNION ALL
    SELECT
        'CATALOG' AS channel,
        cc.cc_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        i.i_item_id AS item_id,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cc.cc_state, d.d_year, d.d_moy, i.i_item_id
    UNION ALL
    SELECT
        'WEB' AS channel,
        ws_site.web_state AS state,
        d.d_year AS year,
        d.d_moy AS month,
        i.i_item_id AS item_id,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws_site.web_state, d.d_year, d.d_moy, i.i_item_id
),
top_item AS (
    SELECT
        channel,
        state,
        year,
        month,
        item_id,
        quantity,
        ROW_NUMBER() OVER (PARTITION BY channel, state, year, month ORDER BY quantity DESC) AS rn
    FROM item_sales
)
SELECT
    s.year,
    s.month,
    s.channel,
    s.state,
    s.sales_amount,
    s.profit_amount,
    s.total_quantity,
    s.total_discount,
    s.total_tax,
    COALESCE(r.return_amount, 0) AS return_amount,
    COALESCE(r.return_loss, 0) AS return_loss,
    COALESCE(r.return_quantity, 0) AS return_quantity,
    s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales,
    s.profit_amount - COALESCE(r.return_loss, 0) AS net_profit,
    RANK() OVER (PARTITION BY s.year, s.month ORDER BY s.sales_amount - COALESCE(r.return_amount, 0) DESC) AS sales_rank,
    ti.item_id AS top_item_id,
    ti.quantity AS top_item_quantity
FROM sales_union s
LEFT JOIN returns_union r
    ON s.channel = r.channel
    AND s.state = r.state
    AND s.year = r.year
    AND s.month = r.month
LEFT JOIN (
    SELECT channel, state, year, month, item_id, quantity
    FROM top_item
    WHERE rn = 1
) ti
    ON s.channel = ti.channel
    AND s.state = ti.state
    AND s.year = ti.year
    AND s.month = ti.month
WHERE s.year = 2001
  AND s.month BETWEEN 1 AND 12
ORDER BY s.year, s.month, s.channel, s.state
