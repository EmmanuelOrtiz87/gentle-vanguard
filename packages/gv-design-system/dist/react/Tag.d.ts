import { type HTMLAttributes, type ReactNode } from 'react';
import './Tag.css';
export type TagVariant = 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'neutral';
export type TagSize = 'sm' | 'md';
export interface TagProps extends HTMLAttributes<HTMLSpanElement> {
    variant?: TagVariant;
    size?: TagSize;
    icon?: ReactNode;
    children: ReactNode;
}
/**
 * Tag — Gentle-Vanguard v2 pill-shaped label.
 * Use for status indicators, categories, metadata.
 *
 * @example
 *   <Tag variant="success">Active</Tag>
 *   <Tag variant="warning" icon={<Icon />}>Pending</Tag>
 *   <Tag variant="primary" size="sm">Beta</Tag>
 */
export declare function Tag({ variant, size, icon, className, children, ...rest }: TagProps): import("react").JSX.Element;
//# sourceMappingURL=Tag.d.ts.map