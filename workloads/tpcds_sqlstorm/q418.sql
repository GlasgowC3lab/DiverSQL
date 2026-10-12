WITH sales_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        i.i_category,
        SUM(cs.cs_net_profit) AS cat_sales_profit,
        SUM(cs.cs_quantity) AS cat_sales_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, ca.ca_state, i.i_category
),
store_sales_agg AS (
    SELECT
        d.d_year,
        s.s_state,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ss.ss_quantity) AS store_sales_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, s.s_state
),
web_sales_agg AS (
    SELECT
        d.d_year,
        w.web_state,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(ws.ws_quantity) AS web_sales_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY d.d_year, w.web_state
),
returns_agg AS (
    SELECT
        d.d_year,
        ca.ca_state,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        SUM(wr.wr_net_loss) AS web_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON cr.cr_order_number = sr.sr_ticket_number
    LEFT JOIN web_returns wr ON cr.cr_order_number = wr.wr_order_number
    LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
)
SELECT
    s.d_year,
    s.ca_state,
    s.i_category,
    s.cat_sales_profit,
    s.cat_sales_quantity,
    st.store_sales_profit,
    st.store_sales_quantity,
    ws.web_sales_profit,
    ws.web_sales_quantity,
    r.catalog_returns_loss,
    r.store_returns_loss,
    r.web_returns_loss,
    (COALESCE(s.cat_sales_profit, 0) + COALESCE(st.store_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0)
     - COALESCE(r.catalog_returns_loss, 0) - COALESCE(r.store_returns_loss, 0) - COALESCE(r.web_returns_loss, 0)) AS net_profit,
    ROW_NUMBER() OVER (
        PARTITION BY s.d_year
        ORDER BY (COALESCE(s.cat_sales_profit, 0) + COALESCE(st.store_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0)
                  - COALESCE(r.catalog_returns_loss, 0) - COALESCE(r.store_returns_loss, 0) - COALESCE(r.web_returns_loss, 0)) DESC
    ) AS profit_rank
FROM sales_agg s
LEFT JOIN store_sales_agg st
    ON s.d_year = st.d_year AND s.ca_state = st.s_state
LEFT JOIN web_sales_agg ws
    ON s.d_year = ws.d_year AND s.ca_state = ws.web_state
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year AND s.ca_state = r.ca_state
ORDER BY net_profit DESC
LIMIT 100
