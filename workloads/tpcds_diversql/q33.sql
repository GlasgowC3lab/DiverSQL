WITH base AS (
    SELECT
        s.s_store_id,
        i.i_category,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_returns_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_returns_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_returns_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND s.s_market_manager = 'Dean Morrison'
      AND i.i_brand_id = 23
    GROUP BY s.s_store_id, i.i_category
)
SELECT
    b.s_store_id,
    b.i_category,
    (
        b.store_sales_profit + b.web_sales_profit + b.catalog_sales_profit
        - b.store_returns_loss - b.catalog_returns_loss - b.web_returns_loss
    ) AS total_profit
FROM base b
WHERE (
        b.store_sales_profit + b.web_sales_profit + b.catalog_sales_profit
        - b.store_returns_loss - b.catalog_returns_loss - b.web_returns_loss
    ) > (
        SELECT AVG(
            store_sales_profit + web_sales_profit + catalog_sales_profit
            - store_returns_loss - catalog_returns_loss - web_returns_loss
        )
        FROM base
    )
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
