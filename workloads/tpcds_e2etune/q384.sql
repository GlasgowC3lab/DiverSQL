WITH cc_open AS (
    SELECT o.d_year AS year,
           COUNT(*) AS opened_cc,
           AVG(cc.cc_employees) AS avg_employees_opened,
           AVG(cc.cc_tax_percentage) AS avg_tax_opened
    FROM call_center cc
    JOIN date_dim o ON cc.cc_open_date_sk = o.d_date_sk
    WHERE o.d_year BETWEEN 1999 AND 2002
    GROUP BY o.d_year
),
cc_closed AS (
    SELECT c.d_year AS year,
           COUNT(*) AS closed_cc,
           AVG(cc.cc_employees) AS avg_employees_closed,
           AVG(cc.cc_tax_percentage) AS avg_tax_closed
    FROM call_center cc
    JOIN date_dim c ON cc.cc_closed_date_sk = c.d_date_sk
    WHERE c.d_year BETWEEN 1999 AND 2002
    GROUP BY c.d_year
),
ws_open AS (
    SELECT o.d_year AS year,
           COUNT(*) AS opened_ws,
           AVG(ws.web_tax_percentage) AS avg_tax_ws
    FROM web_site ws
    JOIN date_dim o ON ws.web_open_date_sk = o.d_date_sk
    WHERE o.d_year BETWEEN 1999 AND 2002
    GROUP BY o.d_year
)
SELECT co.year,
       co.opened_cc,
       co.avg_employees_opened,
       co.avg_tax_opened,
       cc.closed_cc,
       cc.avg_employees_closed,
       cc.avg_tax_closed,
       ws.opened_ws,
       ws.avg_tax_ws,
       (co.opened_cc - COALESCE(cc.closed_cc, 0)) AS net_new_cc,
       RANK() OVER (ORDER BY (co.opened_cc - COALESCE(cc.closed_cc, 0)) DESC) AS year_rank
FROM cc_open co
LEFT JOIN cc_closed cc ON co.year = cc.year
LEFT JOIN ws_open ws ON co.year = ws.year
ORDER BY net_new_cc DESC
