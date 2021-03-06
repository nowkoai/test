import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

// Transforms generated HTML back to GFM for Banzai::Filter::MathFilter
export default () => ({
  name: 'math',
  schema: {
    parseDOM: [
      // Matches HTML generated by Banzai::Filter::MathFilter
      {
        tag: 'code.code.math[data-math-style=inline]',
        priority: HIGHER_PARSE_RULE_PRIORITY,
      },
      // Matches HTML after being transformed by app/assets/javascripts/behaviors/markdown/render_math.js
      {
        tag: 'span.katex',
        contentElement: 'annotation[encoding="application/x-tex"]',
      },
    ],
    toDOM: () => ['code', { class: 'code math', 'data-math-style': 'inline' }, 0],
  },
  toMarkdown: {
    escape: false,
    open(state, mark, parent, index) {
      return `$${defaultMarkdownSerializer.marks.code.open(state, mark, parent, index)}`;
    },
    close(state, mark, parent, index) {
      return `${defaultMarkdownSerializer.marks.code.close(state, mark, parent, index)}$`;
    },
  },
});
