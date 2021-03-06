import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';
import TableRow from './table_row';

const CENTER_ALIGN = 'center';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'table_header_row',
  schema: {
    content: 'table_cell+',
    parseDOM: [
      {
        tag: 'thead tr',
        priority: HIGHER_PARSE_RULE_PRIORITY,
      },
    ],
    toDOM: () => ['tr', 0],
  },
  toMarkdown: (state, node) => {
    const cellWidths = TableRow().toMarkdown(state, node);

    state.flushClose(1);

    state.write('|');
    node.forEach((cell, _, i) => {
      if (i) state.write('|');

      state.write(cell.attrs.align === CENTER_ALIGN ? ':' : '-');
      state.write(state.repeat('-', cellWidths[i]));
      state.write(cell.attrs.align === CENTER_ALIGN || cell.attrs.align === 'right' ? ':' : '-');
    });
    state.write('|');

    state.closeBlock(node);
  },
});
