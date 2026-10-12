WITH catalog_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_class,
        d.d_year,
        d.d_quarter_seq,
        SUM(cs.cs_quantity) AS cat_quantity,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_net_profit) AS cat_profit,
        SUM(cs.cs_ext_discount_amt) AS cat_discount,
        COUNT(DISTINCT cs.cs_order_number) AS cat_orders,
        COALESCE(cc.cc_name, 'UNKNOWN') AS call_center_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, i.i_class, d.d_year, d.d_quarter_seq, cc.cc_name
),
store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_class,
        d.d_year,
        d.d_quarter_seq,
        s.s_state,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, i.i_class, d.d_year, d.d_quarter_seq, s.s_state
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_class,
        d.d_year,
        d.d_quarter_seq,
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, i.i_class, d.d_year, d.d_quarter_seq, ws.ws_web_page_sk
),
catalog_returns_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        d.d_quarter_seq,
        SUM(cr.cr_return_quantity) AS cat_ret_qty,
        SUM(cr.cr_net_loss) AS cat_ret_loss,
        COUNT(DISTINCT cr.cr_order_number) AS cat_ret_orders,
        COALESCE(r.r_reason_desc, 'UNKNOWN') AS cat_ret_reason
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY i.i_item_id, d.d_year, d.d_quarter_seq, r.r_reason_desc
),
store_returns_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        d.d_quarter_seq,
        SUM(sr.sr_return_quantity) AS store_ret_qty,
        SUM(sr.sr_net_loss) AS store_ret_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_ret_tickets,
        COALESCE(r.r_reason_desc, 'UNKNOWN') AS store_ret_reason
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY i.i_item_id, d.d_year, d.d_quarter_seq, r.r_reason_desc
),
web_returns_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        d.d_quarter_seq,
        SUM(wr.wr_return_quantity) AS web_ret_qty,
        SUM(wr.wr_net_loss) AS web_ret_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_ret_orders,
        COALESCE(r.r_reason_desc, 'UNKNOWN') AS web_ret_reason
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY i.i_item_id, d.d_year, d.d_quarter_seq, r.r_reason_desc
),
combined AS (
    SELECT
        ca.i_item_id,
        ca.i_item_desc,
        ca.i_category,
        ca.i_class,
        ca.d_year,
        ca.d_quarter_seq,
        ca.cat_quantity,
        ca.cat_sales,
        ca.cat_profit,
        ca.cat_discount,
        ca.cat_orders,
        ca.call_center_name,
        sa.store_quantity,
        sa.store_sales,
        sa.store_profit,
        sa.store_discount,
        sa.store_transactions,
        sa.s_state,
        wa.web_quantity,
        wa.web_sales,
        wa.web_profit,
        wa.web_discount,
        wa.web_orders,
        wa.ws_web_page_sk,
        ra.cat_ret_qty,
        ra.cat_ret_loss,
        ra.cat_ret_reason,
        srra.store_ret_qty,
        srra.store_ret_loss,
        srra.store_ret_reason,
        wrra.web_ret_qty,
        wrra.web_ret_loss,
        wrra.web_ret_reason
    FROM catalog_sales_agg ca
    FULL OUTER JOIN store_sales_agg sa
        ON ca.i_item_id = sa.i_item_id
        AND ca.d_year = sa.d_year
        AND ca.d_quarter_seq = sa.d_quarter_seq
    FULL OUTER JOIN web_sales_agg wa
        ON COALESCE(ca.i_item_id, sa.i_item_id) = wa.i_item_id
        AND COALESCE(ca.d_year, sa.d_year) = wa.d_year
        AND COALESCE(ca.d_quarter_seq, sa.d_quarter_seq) = wa.d_quarter_seq
    FULL OUTER JOIN catalog_returns_agg ra
        ON COALESCE(ca.i_item_id, sa.i_item_id, wa.i_item_id) = ra.i_item_id
        AND COALESCE(ca.d_year, sa.d_year, wa.d_year) = ra.d_year
        AND COALESCE(ca.d_quarter_seq, sa.d_quarter_seq, wa.d_quarter_seq) = ra.d_quarter_seq
    FULL OUTER JOIN store_returns_agg srra
        ON COALESCE(ca.i_item_id, sa.i_item_id, wa.i_item_id, ra.i_item_id) = srra.i_item_id
        AND COALESCE(ca.d_year, sa.d_year, wa.d_year, ra.d_year) = srra.d_year
        AND COALESCE(ca.d_quarter_seq, sa.d_quarter_seq, wa.d_quarter_seq, ra.d_quarter_seq) = srra.d_quarter_seq
    FULL OUTER JOIN web_returns_agg wrra
        ON COALESCE(ca.i_item_id, sa.i_item_id, wa.i_item_id, ra.i_item_id, srra.i_item_id) = wrra.i_item_id
        AND COALESCE(ca.d_year, sa.d_year, wa.d_year, ra.d_year, srra.d_year) = wrra.d_year
        AND COALESCE(ca.d_quarter_seq, sa.d_quarter_seq, wa.d_quarter_seq, ra.d_quarter_seq, srra.d_quarter_seq) = wrra.d_quarter_seq
),
final AS (
    SELECT
        i_item_id,
        i_item_desc,
        i_category,
        i_class,
        d_year,
        d_quarter_seq,
        COALESCE(cat_quantity, 0) + COALESCE(store_quantity, 0) + COALESCE(web_quantity, 0) AS total_quantity,
        COALESCE(cat_sales, 0) + COALESCE(store_sales, 0) + COALESCE(web_sales, 0) AS total_sales,
        COALESCE(cat_profit, 0) + COALESCE(store_profit, 0) + COALESCE(web_profit, 0) AS total_profit,
        COALESCE(cat_ret_qty, 0) + COALESCE(store_ret_qty, 0) + COALESCE(web_ret_qty, 0) AS total_ret_qty,
        COALESCE(cat_ret_loss, 0) + COALESCE(store_ret_loss, 0) + COALESCE(web_ret_loss, 0) AS total_ret_loss,
        (COALESCE(cat_sales, 0) + COALESCE(store_sales, 0) + COALESCE(web_sales, 0))
            - (COALESCE(cat_ret_loss, 0) + COALESCE(store_ret_loss, 0) + COALESCE(web_ret_loss, 0)) AS net_sales,
        (COALESCE(cat_profit, 0) + COALESCE(store_profit, 0) + COALESCE(web_profit, 0))
            - (COALESCE(cat_ret_loss, 0) + COALESCE(store_ret_loss, 0) + COALESCE(web_ret_loss, 0)) AS net_profit,
        CASE
            WHEN (COALESCE(cat_sales, 0) + COALESCE(store_sales, 0) + COALESCE(web_sales, 0)) = 0 THEN 0
            ELSE ((COALESCE(cat_profit, 0) + COALESCE(store_profit, 0) + COALESCE(web_profit, 0))
                - (COALESCE(cat_ret_loss, 0) + COALESCE(store_ret_loss, 0) + COALESCE(web_ret_loss, 0)))
                / (COALESCE(cat_sales, 0) + COALESCE(store_sales, 0) + COALESCE(web_sales, 0))
        END AS net_margin,
        ROW_NUMBER() OVER (
            PARTITION BY d_year
            ORDER BY ((COALESCE(cat_profit, 0) + COALESCE(store_profit, 0) + COALESCE(web_profit, 0))
                - (COALESCE(cat_ret_loss, 0) + COALESCE(store_ret_loss, 0) + COALESCE(web_ret_loss, 0))) DESC
        ) AS profit_rank_year,
        call_center_name,
        s_state,
        ws_web_page_sk,
        cat_ret_reason,
        store_ret_reason,
        web_ret_reason
    FROM combined
)
SELECT *
FROM final
WHERE total_sales > 0
ORDER BY d_year, net_profit DESC
LIMIT 100
