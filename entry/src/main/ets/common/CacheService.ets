import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
let appContext: common.Context | undefined;
function contextOrThrow(): common.Context { if (!appContext) { throw new Error('缓存服务尚未初始化'); } return appContext; }
function directorySize(path: string): number {
    let total = 0;
    try {
        const names = fileIo.listFileSync(path);
        names.forEach((name: string) => {
            const child = `${path}/${name}`;
            const stat = fileIo.statSync(child);
            total += stat.isDirectory() ? directorySize(child) : stat.size;
        });
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 统计缓存失败: ${JSON.stringify(error)}`);
    }
    return total;
}

export function getCacheSizeBytes(context?: common.Context): number {
    if (context) {
        appContext = context;
    }
    try {
        return directorySize(contextOrThrow().cacheDir);
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 缓存容量读取失败: ${JSON.stringify(error)}`);
        return 0;
    }
}

function clearDirectory(path: string, keepRoot: boolean): boolean {
    try {
        if (!fileIo.accessSync(path)) {
            return true;
        }
        let completelyCleared = true;
        const names = fileIo.listFileSync(path);
        names.forEach((name: string) => {
            const child = `${path}/${name}`;
            try {
                const stat = fileIo.statSync(child);
                if (stat.isDirectory()) {
                    completelyCleared = clearDirectory(child, false) && completelyCleared;
                } else {
                    fileIo.unlinkSync(child);
                }
            } catch (error) {
                completelyCleared = false;
                console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 清理缓存项失败 ${child}: ${JSON.stringify(error)}`);
            }
        });
        if (!keepRoot && completelyCleared) {
            fileIo.rmdirSync(path);
        }
        return completelyCleared;
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 无法遍历缓存目录 ${path}: ${JSON.stringify(error)}`);
        return false;
    }
}


export async function clearCompleteCache(context: common.Context): Promise<void> {
  if (!clearDirectory(context.cacheDir, true)) { throw new Error("部分缓存文件正在使用"); }
}
