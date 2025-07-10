<template>
  <div class="tools-container">
    <div class="page-header">
      <div class="header-content">
        <h1>创作工具</h1>
        <p>提升您的创作效率</p>
      </div>
    </div>

    <div class="tools-grid">
      <div class="tool-card">
        <div class="tool-icon">🎲</div>
        <h3>情节生成器</h3>
        <p>随机生成创意情节，激发您的创作灵感</p>
        <button class="btn btn-primary" @click="generatePlot">
          生成情节
        </button>
      </div>

      <div class="tool-card">
        <div class="tool-icon">🎭</div>
        <h3>人物生成器</h3>
        <p>创造具有个性的角色，丰富您的故事</p>
        <button class="btn btn-primary" @click="generateCharacter">
          生成人物
        </button>
      </div>

      <div class="tool-card">
        <div class="tool-icon">🌍</div>
        <h3>世界构建</h3>
        <p>构建详细的故事世界和背景设定</p>
        <button class="btn btn-primary" @click="buildWorld">
          构建世界
        </button>
      </div>

      <div class="tool-card">
        <div class="tool-icon">📊</div>
        <h3>情节分析</h3>
        <p>分析您的故事结构和情节发展</p>
        <button class="btn btn-primary" @click="analyzePlot">
          分析情节
        </button>
      </div>

      <div class="tool-card">
        <div class="tool-icon">✨</div>
        <h3>文本优化</h3>
        <p>优化您的文本，提升语言表达效果</p>
        <button class="btn btn-primary" @click="optimizeText">
          优化文本
        </button>
      </div>

      <div class="tool-card">
        <div class="tool-icon">🎨</div>
        <h3>风格转换</h3>
        <p>尝试不同的写作风格和语调</p>
        <button class="btn btn-primary" @click="changeStyle">
          转换风格
        </button>
      </div>
    </div>

    <!-- 工具结果显示 -->
    <div v-if="toolResult" class="result-panel">
      <div class="result-header">
        <h3>{{ toolResult.title }}</h3>
        <button class="close-btn" @click="toolResult = null">×</button>
      </div>
      <div class="result-content">
        {{ toolResult.content }}
      </div>
      <div class="result-actions">
        <button class="btn btn-outline" @click="copyResult">
          复制结果
        </button>
        <button class="btn btn-primary" @click="saveResult">
          保存结果
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const toolResult = ref(null)

const generatePlot = () => {
  // 模拟AI生成情节
  const plots = [
    '主角发现了一个神秘的古老卷轴，上面记载着失落已久的魔法咒语。',
    '一个普通的雨夜，主角意外救下了一个神秘的陌生人，从此卷入了一场阴谋。',
    '主角的平静生活被一封来自未来的信件打破，信中预言了即将发生的灾难。',
    '在探索废弃的图书馆时，主角发现了一本会自己翻页的书籍。',
    '主角在梦中反复出现的场景，竟然在现实中真实存在。'
  ]
  
  const randomPlot = plots[Math.floor(Math.random() * plots.length)]
  
  toolResult.value = {
    title: '情节生成结果',
    content: randomPlot
  }
}

const generateCharacter = () => {
  const characters = [
    '艾莉丝·温斯顿 - 一位年轻的图书管理员，拥有过目不忘的记忆力，但对社交感到恐惧。她的秘密是能够进入书籍中的世界。',
    '马库斯·格雷 - 前军官，现在是私人侦探。他有着钢铁般的意志，但内心深处藏着对过去战争的创伤。',
    '露娜·夜星 - 神秘的占星师，能够通过星象预测未来。她总是穿着深蓝色的斗篷，说话带有诗意。',
    '托马斯·布莱克 - 天才发明家，创造了许多不可思议的机械装置。他的实验室隐藏在城市的地下。',
    '薇薇安·罗斯 - 优雅的贵族女性，表面上是社交名媛，实际上是秘密组织的间谍。'
  ]
  
  const randomCharacter = characters[Math.floor(Math.random() * characters.length)]
  
  toolResult.value = {
    title: '人物生成结果',
    content: randomCharacter
  }
}

const buildWorld = () => {
  const worlds = [
    '暮光之城 - 一座建在悬崖边的古老城市，被永恒的黄昏笼罩。城中的时钟塔每到午夜就会发出神秘的钟声，传说能够沟通过去和未来。',
    '水晶森林 - 一片由水晶树组成的神奇森林，阳光透过水晶折射出绚烂的光芒。森林深处住着会说话的动物和古老的精灵。',
    '蒸汽朋克都市 - 一座充满蒸汽机械的工业城市，高耸的烟囱释放着蒸汽，铜制的管道纵横交错。人们穿着维多利亚时代的服装，使用各种奇妙的机械装置。',
    '漂浮岛屿 - 数十座岛屿悬浮在云层之上，通过巨大的锁链相连。岛屿上生活着会飞的民族，他们驾驶着蒸汽动力的飞行器在云间穿梭。',
    '地底王国 - 一个隐藏在地底深处的庞大王国，由发光的真菌照亮。王国中央有一座巨大的地底湖泊，湖水具有神奇的治愈力量。'
  ]
  
  const randomWorld = worlds[Math.floor(Math.random() * worlds.length)]
  
  toolResult.value = {
    title: '世界构建结果',
    content: randomWorld
  }
}

const analyzePlot = () => {
  toolResult.value = {
    title: '情节分析结果',
    content: '您的故事结构分析：\n\n开端：人物介绍和背景设定完整，成功建立了读者的兴趣。\n\n发展：情节推进自然，冲突设置合理，人物关系发展有层次。\n\n高潮：冲突达到顶点，情感张力充分，转折点设计巧妙。\n\n结局：解决方案令人满意，留有适当的想象空间。\n\n建议：可以在中间部分增加一些小高潮，提升故事的节奏感。'
  }
}

const optimizeText = () => {
  toolResult.value = {
    title: '文本优化建议',
    content: '文本优化建议：\n\n1. 使用更加生动的形容词和副词\n2. 增加感官描述，让读者身临其境\n3. 适当使用比喻和拟人等修辞手法\n4. 调整句子长短，创造节奏感\n5. 删除冗余的词汇，保持语言简洁有力\n\n示例：\n原文：他走得很快。\n优化：他大步流星地穿过街道，脚步声在静谧的夜晚显得格外响亮。'
  }
}

const changeStyle = () => {
  const styles = [
    '古典文学风格：语言优美典雅，句式工整，多用排比和对仗，营造诗意的氛围。',
    '现代简约风格：语言简洁明快，句子短小精悍，注重对话的真实性和人物的内心描写。',
    '悬疑推理风格：语言紧张刺激，多用短句营造紧迫感，善于埋伏笔和制造悬念。',
    '奇幻冒险风格：语言富有想象力，多用夸张和比喻，描述充满奇思妙想的世界。',
    '科幻未来风格：语言精准理性，多用科技术语，注重逻辑性和未来感的营造。'
  ]
  
  const randomStyle = styles[Math.floor(Math.random() * styles.length)]
  
  toolResult.value = {
    title: '风格转换建议',
    content: randomStyle
  }
}

const copyResult = () => {
  if (toolResult.value) {
    navigator.clipboard.writeText(toolResult.value.content)
    alert('结果已复制到剪贴板')
  }
}

const saveResult = () => {
  if (toolResult.value) {
    // 这里可以实现保存到本地或服务器的功能
    alert('结果已保存')
  }
}
</script>

<style scoped>
.tools-container {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 3rem;
}

.header-content h1 {
  font-size: 2.5rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.header-content p {
  color: #666;
  font-size: 1.1rem;
}

.tools-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin-bottom: 3rem;
}

.tool-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  padding: 2rem;
  text-align: center;
  transition: all 0.3s;
}

.tool-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.tool-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.tool-card h3 {
  font-size: 1.3rem;
  color: #2c3e50;
  margin-bottom: 1rem;
}

.tool-card p {
  color: #666;
  line-height: 1.6;
  margin-bottom: 1.5rem;
}

.btn {
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
}

.btn-primary {
  background: #409eff;
  color: white;
}

.btn-primary:hover {
  background: #337ecc;
  transform: translateY(-2px);
}

.btn-outline {
  background: transparent;
  border: 1px solid #409eff;
  color: #409eff;
}

.btn-outline:hover {
  background: #409eff;
  color: white;
}

.result-panel {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  margin-top: 2rem;
}

.result-header {
  background: #f8f9fa;
  padding: 1rem 2rem;
  border-bottom: 1px solid #e1e8ed;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.result-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.2rem;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s;
}

.close-btn:hover {
  background: #e9ecef;
}

.result-content {
  padding: 2rem;
  line-height: 1.8;
  color: #2c3e50;
  white-space: pre-line;
  font-size: 1rem;
}

.result-actions {
  padding: 1rem 2rem;
  border-top: 1px solid #e1e8ed;
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

@media (max-width: 768px) {
  .tools-container {
    padding: 1rem;
  }
  
  .header-content h1 {
    font-size: 2rem;
  }
  
  .tools-grid {
    grid-template-columns: 1fr;
  }
  
  .tool-card {
    padding: 1.5rem;
  }
  
  .result-actions {
    flex-direction: column;
  }
}
</style>
