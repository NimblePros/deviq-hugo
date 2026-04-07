---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
description: ""
params:
  image: /{{ replace .File.Dir "\\" "/" }}images/{{ .File.ContentBaseName }}-400x400.jpg
weight: 100
draft: true
---

<!-- TODO: Create image file at static/{{ replace .File.Dir "\\" "/" }}images/{{ .File.ContentBaseName }}-400x400.jpg -->
