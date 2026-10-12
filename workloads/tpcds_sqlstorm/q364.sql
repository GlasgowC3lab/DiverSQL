WITH sales_returns AS (
    SELECT 
        d.d_year AS year,
        cc.cc_state AS state,
        i.i_category AS category,
        cd.cd_gender AS gender,
        SUM(cs.cs_ext_sales_price) AS amt,
        SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, cc.cc_state, i.i_category, cd.cd_gender

    UNION ALL

    SELECT 
        d.d_year,
        cc.cc_state,
        i.i_category,
        cd.cd_gender,
        -SUM(cr.cr_return_amount) AS amt,
        -SUM(cr.cr_net_loss) AS profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, cc.cc_state, i.i_category, cd.cd_gender

    UNION ALL

    SELECT 
        d.d_year,
        s.s_state,
        i.i_category,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS amt,
        SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, s.s_state, i.i_category, cd.cd_gender

    UNION ALL

    SELECT 
        d.d_year,
        s.s_state,
        i.i_category,
        cd.cd_gender,
        -SUM(sr.sr_return_amt) AS amt,
        -SUM(sr.sr_net_loss) AS profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, s.s_state, i.i_category, cd.cd_gender

    UNION ALL

    SELECT 
        d.d_year,
        w.web_state,
        i.i_category,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS amt,
        SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, w.web_state, i.i_category, cd.cd_gender
), agg AS (
    SELECT 
        year,
        state,
        category,
        gender,
        SUM(amt) AS net_sales_amount,
        SUM(profit) AS net_profit
    FROM sales_returns
    GROUP BY year, state, category, gender
    HAVING SUM(amt) > 0
)
SELECT 
    year,
    state,
    category,
    gender,
    net_sales_amount,
    net_profit,
    SUM(net_profit) OVER (PARTITION BY state ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY net_profit DESC) AS profit_rank
FROM agg
ORDER BY year, profit_rank
LIMIT 200
