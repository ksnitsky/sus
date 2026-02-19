// components/layout.gleam
// Common layout for all pages

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Main page layout
pub fn layout(title: String, children: List(Element(msg))) -> Element(msg) {
  html.html([attribute.lang("ru")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.title([], title),
      html.style([], inline_styles()),
    ]),
    html.body(
      [
        attribute.styles([
          #("max-width", "800px"),
          #("margin", "0 auto"),
          #("padding", "20px"),
        ]),
      ],
      [
        html.header([], [
          html.h1([], [html.text("Task Tracker")]),
        ]),
        html.main([], children),
        html.footer(
          [
            attribute.styles([
              #("margin-top", "40px"),
              #("text-align", "center"),
              #("color", "#666"),
            ]),
          ],
          [html.text("Task Tracker © 2025")],
        ),
      ],
    ),
  ])
}

/// Inline CSS styles
fn inline_styles() -> String {
  "
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f5f5f5;
  color: #333;
  line-height: 1.6;
}

h1 {
  color: #2c3e50;
  border-bottom: 3px solid #3498db;
  padding-bottom: 10px;
}

.task-form {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 600;
  color: #555;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  box-sizing: border-box;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  transition: background 0.2s;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover {
  background: #2980b9;
}

.btn-success {
  background: #27ae60;
  color: white;
}

.btn-success:hover {
  background: #229954;
}

.btn-warning {
  background: #f39c12;
  color: white;
}

.btn-warning:hover {
  background: #e67e22;
}

.btn-danger {
  background: #e74c3c;
  color: white;
}

.btn-danger:hover {
  background: #c0392b;
}

.task-list {
  list-style: none;
  padding: 0;
}

.task-item {
  background: white;
  padding: 20px;
  margin-bottom: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  border-left: 4px solid #3498db;
}

.task-item.status-not-started {
  border-left-color: #95a5a6;
}

.task-item.status-in-progress {
  border-left-color: #3498db;
}

.task-item.status-completed {
  border-left-color: #27ae60;
}

.task-item.status-paused {
  border-left-color: #f39c12;
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.task-name {
  font-size: 18px;
  font-weight: 600;
  color: #2c3e50;
  margin: 0;
}

.task-status {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.task-status.status-not-started {
  background: #ecf0f1;
  color: #7f8c8d;
}

.task-status.status-in-progress {
  background: #ebf5fb;
  color: #3498db;
}

.task-status.status-completed {
  background: #eafaf1;
  color: #27ae60;
}

.task-status.status-paused {
  background: #fef5e7;
  color: #f39c12;
}

.task-description {
  color: #666;
  margin-bottom: 15px;
}

.task-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.task-time {
  font-family: 'Courier New', monospace;
  font-size: 20px;
  font-weight: 600;
  color: #2c3e50;
}

.task-actions {
  display: flex;
  gap: 10px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #7f8c8d;
}

.empty-state h3 {
  color: #95a5a6;
  margin-bottom: 10px;
}
"
}
