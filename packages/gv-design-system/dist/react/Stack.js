import { jsx as _jsx } from "react/jsx-runtime";
import { forwardRef } from 'react';
import './Stack.css';
const alignMap = {
    start: 'flex-start',
    center: 'center',
    end: 'flex-end',
    stretch: 'stretch',
    baseline: 'baseline',
};
const justifyMap = {
    start: 'flex-start',
    center: 'center',
    end: 'flex-end',
    between: 'space-between',
    around: 'space-around',
    evenly: 'space-evenly',
};
const gapMap = {
    0: '0',
    1: 'var(--gv-space-1)',
    2: 'var(--gv-space-2)',
    3: 'var(--gv-space-3)',
    4: 'var(--gv-space-4)',
    5: 'var(--gv-space-5)',
    6: 'var(--gv-space-6)',
    8: 'var(--gv-space-8)',
    10: 'var(--gv-space-10)',
    12: 'var(--gv-space-12)',
    16: 'var(--gv-space-16)',
    20: 'var(--gv-space-20)',
    24: 'var(--gv-space-24)',
};
/**
 * Stack — Gentle-Vanguard v2 flex layout primitive.
 * Thin wrapper over CSS flexbox with token-based gap scale.
 *
 * @example
 *   <Stack direction="row" gap={4} align="center">
 *     <Logo />
 *     <Title>Dashboard</Title>
 *   </Stack>
 *   <Stack direction="column" gap={6}>
 *     <Header />
 *     <Body />
 *   </Stack>
 */
export const Stack = forwardRef(function Stack({ direction = 'column', align, justify, wrap, gap = 4, inline = false, as: Tag = 'div', className = '', style, children, ...rest }, ref) {
    const cssStyle = {
        display: inline ? 'inline-flex' : 'flex',
        flexDirection: direction,
        alignItems: align ? alignMap[align] : undefined,
        justifyContent: justify ? justifyMap[justify] : undefined,
        flexWrap: wrap,
        gap: gapMap[gap],
        ...style,
    };
    const classes = ['gv-stack', className].filter(Boolean).join(' ');
    return (_jsx(Tag, { ref: ref, className: classes, style: cssStyle, ...rest, children: children }));
});
//# sourceMappingURL=Stack.js.map